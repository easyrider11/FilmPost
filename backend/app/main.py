from functools import lru_cache

from fastapi import Depends, FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

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


@lru_cache(maxsize=1)
def build_analysis_service() -> OpenAIAnalysisService:
    return OpenAIAnalysisService(get_settings())


def get_analysis_service() -> AnalysisService:
    return build_analysis_service()


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/analyze", response_model=AnalysisResponse)
async def analyze_images(
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
