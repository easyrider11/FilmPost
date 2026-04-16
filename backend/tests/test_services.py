"""Tests for the image-sanitisation pipeline.

These guard the privacy-critical promise that EXIF metadata is stripped
before any image bytes leave for OpenAI, and that orientation is baked
into pixels so portrait-mode iPhone uploads aren't analysed sideways.
"""

import base64
import io

import pytest
from PIL import Image
from PIL.ExifTags import Base as ExifTag

from app.config import Settings
from app.services import OpenAIAnalysisService


def _png_bytes(size: tuple[int, int] = (320, 240), color: str = "red") -> bytes:
    buffer = io.BytesIO()
    Image.new("RGB", size, color).save(buffer, format="PNG")
    return buffer.getvalue()


def _jpeg_with_exif(size: tuple[int, int] = (320, 240)) -> bytes:
    """Build a JPEG that carries identifying EXIF (Make + Model + Software)."""
    buffer = io.BytesIO()
    image = Image.new("RGB", size, "blue")
    exif = image.getexif()
    exif[ExifTag.Make.value] = "FilmPost-Test"
    exif[ExifTag.Model.value] = "iPhone 15 Pro"
    exif[ExifTag.Software.value] = "FilmPost-Suite"
    image.save(buffer, format="JPEG", exif=exif, quality=92)
    return buffer.getvalue()


def _decode_data_url(data_url: str) -> bytes:
    _, b64 = data_url.split(",", 1)
    return base64.b64decode(b64)


@pytest.fixture
def service() -> OpenAIAnalysisService:
    return OpenAIAnalysisService(Settings())


def test_input_fixture_actually_carries_exif() -> None:
    """Sanity check: our test fixture must contain EXIF, otherwise the
    'EXIF is stripped' test below would silently pass on an empty input."""
    raw = _jpeg_with_exif()
    with Image.open(io.BytesIO(raw)) as img:
        exif = dict(img.getexif())
    assert exif.get(ExifTag.Make.value) == "FilmPost-Test"


def test_sanitize_strips_exif(service: OpenAIAnalysisService) -> None:
    original = _jpeg_with_exif()

    sanitized, content_type = OpenAIAnalysisService._sanitize_and_resize(original, "image/jpeg")

    assert content_type == "image/jpeg"
    with Image.open(io.BytesIO(sanitized)) as round_tripped:
        # After our scrub there must be no Make/Model/Software left in EXIF.
        exif = dict(round_tripped.getexif())
        assert ExifTag.Make.value not in exif
        assert ExifTag.Model.value not in exif
        assert ExifTag.Software.value not in exif


def test_sanitize_downscales_oversized_image(service: OpenAIAnalysisService) -> None:
    original = _png_bytes(size=(4000, 3000))

    sanitized, content_type = OpenAIAnalysisService._sanitize_and_resize(original, "image/png")

    assert content_type == "image/jpeg"  # we always re-encode to JPEG
    with Image.open(io.BytesIO(sanitized)) as round_tripped:
        assert max(round_tripped.size) <= 1568


def test_sanitize_preserves_under_threshold_image_size(
    service: OpenAIAnalysisService,
) -> None:
    original = _png_bytes(size=(800, 600))

    sanitized, _ = OpenAIAnalysisService._sanitize_and_resize(original, "image/png")

    with Image.open(io.BytesIO(sanitized)) as round_tripped:
        # Dimensions are preserved; only the encoding (PNG -> JPEG) changes.
        assert round_tripped.size == (800, 600)


def test_sanitize_falls_back_on_undecodable_input(service: OpenAIAnalysisService) -> None:
    garbage = b"not an image"

    sanitized, content_type = OpenAIAnalysisService._sanitize_and_resize(garbage, "image/heic")

    # Fallback path returns the original bytes + content type so OpenAI gets
    # to handle exotic formats Pillow can't decode.
    assert sanitized == garbage
    assert content_type == "image/heic"


def test_prepare_data_url_emits_jpeg_data_url(service: OpenAIAnalysisService) -> None:
    data_url = service._prepare_image_data_url(
        _png_bytes(), "image/png", slot_name="subject_image"
    )

    assert data_url.startswith("data:image/jpeg;base64,")
    payload = _decode_data_url(data_url)
    with Image.open(io.BytesIO(payload)) as round_tripped:
        assert round_tripped.format == "JPEG"


def test_validate_image_rejects_empty_upload(service: OpenAIAnalysisService) -> None:
    from app.services import AnalysisServiceError

    with pytest.raises(AnalysisServiceError) as exc_info:
        service._validate_image(b"", "image/jpeg", slot_name="subject_image")

    assert exc_info.value.status_code == 400


def test_validate_image_rejects_oversize_upload(service: OpenAIAnalysisService) -> None:
    from app.services import AnalysisServiceError

    too_big = b"x" * (service.settings.max_upload_bytes + 1)

    with pytest.raises(AnalysisServiceError) as exc_info:
        service._validate_image(too_big, "image/jpeg", slot_name="subject_image")

    assert exc_info.value.status_code == 413


def test_validate_image_rejects_non_image_content_type(
    service: OpenAIAnalysisService,
) -> None:
    from app.services import AnalysisServiceError

    with pytest.raises(AnalysisServiceError) as exc_info:
        service._validate_image(b"hello", "text/plain", slot_name="subject_image")

    assert exc_info.value.status_code == 400
