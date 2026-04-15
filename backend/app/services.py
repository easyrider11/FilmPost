import base64
import io
from typing import Protocol

from openai import APIError, APITimeoutError, AsyncOpenAI, OpenAIError
from PIL import Image, UnidentifiedImageError

from app.config import Settings
from app.models import AnalysisResponse
from app.prompts import ANALYSIS_SYSTEM_PROMPT, build_user_prompt

# OpenAI's vision models don't benefit from resolutions above ~1568px on the
# long edge at "high" detail. Downscaling before base64-encoding cuts upload
# bytes to OpenAI (and wall-clock latency) without hurting coaching quality.
_MAX_IMAGE_LONG_EDGE = 1568
_JPEG_QUALITY = 85


class AnalysisServiceError(Exception):
    def __init__(self, message: str, *, status_code: int = 500) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class AnalysisService(Protocol):
    async def analyze(
        self,
        *,
        subject_bytes: bytes,
        subject_content_type: str,
        background_bytes: bytes,
        background_content_type: str,
    ) -> AnalysisResponse: ...


class OpenAIAnalysisService:
    def __init__(self, settings: Settings, client: AsyncOpenAI | None = None) -> None:
        self.settings = settings
        # Reuse a single AsyncOpenAI client across requests so we don't pay the
        # connection-pool setup cost on every analyze call. The client is created
        # lazily the first time we have a key to avoid crashing boot in envs
        # (tests, CI, first-run) where the key isn't configured yet.
        self._client = client
        self._owns_client = client is None

    async def analyze(
        self,
        *,
        subject_bytes: bytes,
        subject_content_type: str,
        background_bytes: bytes,
        background_content_type: str,
    ) -> AnalysisResponse:
        if not self.settings.openai_api_key:
            raise AnalysisServiceError(
                "OpenAI API key is missing. Add OPENAI_API_KEY to backend/.env before analyzing images.",
                status_code=503,
            )

        self._validate_image(subject_bytes, subject_content_type, slot_name="subject_image")
        self._validate_image(background_bytes, background_content_type, slot_name="background_image")

        subject_url = self._prepare_image_data_url(
            subject_bytes, subject_content_type, slot_name="subject_image"
        )
        background_url = self._prepare_image_data_url(
            background_bytes, background_content_type, slot_name="background_image"
        )

        client = self._get_client()

        try:
            response = await client.responses.parse(
                model=self.settings.openai_model,
                input=[
                    {
                        "role": "system",
                        "content": [{"type": "input_text", "text": ANALYSIS_SYSTEM_PROMPT}],
                    },
                    {
                        "role": "user",
                        "content": [
                            {"type": "input_text", "text": build_user_prompt()},
                            {"type": "input_text", "text": "Subject / portrait image:"},
                            {
                                "type": "input_image",
                                "image_url": subject_url,
                                "detail": "high",
                            },
                            {"type": "input_text", "text": "Background / environment image:"},
                            {
                                "type": "input_image",
                                "image_url": background_url,
                                "detail": "high",
                            },
                        ],
                    },
                ],
                text_format=AnalysisResponse,
            )
        except APITimeoutError as exc:
            raise AnalysisServiceError("OpenAI timed out while analyzing images. Please retry.") from exc
        except APIError as exc:
            raise AnalysisServiceError("OpenAI returned an API error while analyzing images.") from exc
        except OpenAIError as exc:
            raise AnalysisServiceError("OpenAI request failed before FilmPost could finish analysis.") from exc

        parsed = response.output_parsed
        if parsed is None:
            raise AnalysisServiceError("OpenAI returned an empty analysis payload.")

        return parsed

    def _validate_image(self, image_bytes: bytes, content_type: str, *, slot_name: str) -> None:
        if not image_bytes:
            raise AnalysisServiceError(f"{slot_name} was empty.", status_code=400)
        if len(image_bytes) > self.settings.max_upload_bytes:
            raise AnalysisServiceError(
                f"{slot_name} exceeded the {self.settings.max_upload_bytes // (1024 * 1024)} MB upload limit.",
                status_code=413,
            )
        if not content_type.startswith("image/"):
            raise AnalysisServiceError(f"{slot_name} must be an image upload.", status_code=400)

    def _get_client(self) -> AsyncOpenAI:
        if self._client is None:
            self._client = AsyncOpenAI(api_key=self.settings.openai_api_key)
            self._owns_client = True
        return self._client

    def _prepare_image_data_url(
        self, image_bytes: bytes, content_type: str, *, slot_name: str
    ) -> str:
        downscaled_bytes, out_content_type = self._maybe_downscale(image_bytes, content_type)
        encoded = base64.b64encode(downscaled_bytes).decode("utf-8")
        return f"data:{out_content_type};base64,{encoded}"

    @staticmethod
    def _maybe_downscale(image_bytes: bytes, content_type: str) -> tuple[bytes, str]:
        """Downscale oversized images to cut OpenAI upload cost/latency.

        Falls back to the original bytes if Pillow can't decode the upload —
        we'd rather let OpenAI handle an unusual format than fail the request.
        """
        try:
            with Image.open(io.BytesIO(image_bytes)) as img:
                long_edge = max(img.size)
                if long_edge <= _MAX_IMAGE_LONG_EDGE:
                    return image_bytes, content_type

                img.thumbnail(
                    (_MAX_IMAGE_LONG_EDGE, _MAX_IMAGE_LONG_EDGE),
                    Image.Resampling.LANCZOS,
                )
                buffer = io.BytesIO()
                if img.mode in ("RGBA", "LA", "P"):
                    img = img.convert("RGB")
                img.save(buffer, format="JPEG", quality=_JPEG_QUALITY, optimize=True)
                return buffer.getvalue(), "image/jpeg"
        except (UnidentifiedImageError, OSError):
            return image_bytes, content_type
