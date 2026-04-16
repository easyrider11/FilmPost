from functools import lru_cache

from fastapi import Depends, FastAPI, File, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.config import Settings, get_settings
from app.models import AnalysisResponse
from app.services import AnalysisService, AnalysisServiceError, OpenAIAnalysisService

app = FastAPI(
    title="FilmPost API",
    version="0.1.0",
    summary="AI photography coaching backend for cinematic photo direction.",
)

settings = get_settings()
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Per-IP rate limiting on the OpenAI-burning endpoint. Without this the
# operator's API budget is exposed to anyone who can reach the URL.
# `enabled` honours FILMPOST_RATE_LIMIT_ENABLED so tests / CI can turn it
# off without faking IPs.
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[],
    enabled=settings.rate_limit_enabled,
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


@lru_cache(maxsize=1)
def build_analysis_service() -> OpenAIAnalysisService:
    return OpenAIAnalysisService(get_settings())


def get_analysis_service() -> AnalysisService:
    return build_analysis_service()


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


# Compound limit string ("10/minute;100/day") protects against both burst
# abuse and a slow grind. Tunable via FILMPOST_RATE_LIMIT_PER_MINUTE /
# _PER_DAY env vars.
@app.post("/v1/analyze", response_model=AnalysisResponse)
@limiter.limit(f"{settings.rate_limit_per_minute};{settings.rate_limit_per_day}")
async def analyze_images(
    request: Request,
    subject_image: UploadFile = File(...),
    background_image: UploadFile = File(...),
    analysis_service: AnalysisService = Depends(get_analysis_service),
) -> AnalysisResponse:
    try:
        return await analysis_service.analyze(
            subject_bytes=await subject_image.read(),
            subject_content_type=subject_image.content_type or "application/octet-stream",
            background_bytes=await background_image.read(),
            background_content_type=background_image.content_type or "application/octet-stream",
        )
    except AnalysisServiceError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
