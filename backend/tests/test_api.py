from fastapi.testclient import TestClient

from app.main import app, get_analysis_service
from app.models import AnalysisResponse, Recommendation


class StubAnalysisService:
    async def analyze(
        self,
        *,
        subject_bytes: bytes,
        subject_content_type: str,
        background_bytes: bytes,
        background_content_type: str,
    ) -> AnalysisResponse:
        assert subject_bytes == b"subject"
        assert background_bytes == b"background"
        assert subject_content_type == "image/jpeg"
        assert background_content_type == "image/png"

        return AnalysisResponse(
            context_summary="Moody transit platform with soft overhead spill and repeating perspective lines.",
            recommendations=[
                Recommendation(
                    style="Late Train Stillness",
                    why_this_matches="Tunnel geometry and cool light support a quiet observational portrait, unlike the others.",
                    pose="One shoulder against tile wall, chin slightly lowered.",
                    composition="Negative space toward tracks, tiles as rhythm.",
                    color_direction="steel blue, pale amber, restrained contrast",
                    camera_distance="1.5 m, medium close",
                    lighting_tip="overhead spill, soft on brow and cheek",
                    reference_film_mood="lonely metropolitan calm",
                ),
                Recommendation(
                    style="Subdued Platform Romance",
                    why_this_matches="The clean linear background supports a softer, more intimate cinematic read than the other two.",
                    pose="Hands relaxed near coat pockets, look past camera.",
                    composition="Mid-torso, subject on left third, receding rails behind.",
                    color_direction="subdued navy, warm skin, softened whites",
                    camera_distance="2 m, medium shot",
                    lighting_tip="brighter overhead patch, background slightly darker",
                    reference_film_mood="tender city-night melancholy",
                ),
                Recommendation(
                    style="Architectural Solitude",
                    why_this_matches="Repetition in the environment isolates the subject with symmetry, distinct from the other two.",
                    pose="Square stance, shoulders loose, eyes level.",
                    composition="Centered body, platform lines pull the eye inward.",
                    color_direction="cool grays, small warm skin accent",
                    camera_distance="3 m, wide medium",
                    lighting_tip="expose for face, far platform lights bloom",
                    reference_film_mood="controlled modern noir",
                ),
            ],
        )


def test_analyze_endpoint_returns_structured_response() -> None:
    app.dependency_overrides[get_analysis_service] = lambda: StubAnalysisService()
    client = TestClient(app)

    response = client.post(
        "/v1/analyze",
        files={
            "subject_image": ("subject.jpg", b"subject", "image/jpeg"),
            "background_image": ("background.png", b"background", "image/png"),
        },
    )

    app.dependency_overrides.clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload["context_summary"].startswith("Moody transit platform")
    assert len(payload["recommendations"]) == 3
    assert payload["recommendations"][0]["style"] == "Late Train Stillness"
