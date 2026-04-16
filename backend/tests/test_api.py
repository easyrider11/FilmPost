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
                    director_note="Hold the body still and let the eyes drift as if the train already left.",
                    emotional_goal="Lonely calm with private interiority.",
                    pose="One shoulder against tile wall, chin slightly lowered.",
                    composition="Negative space toward tracks, tiles as rhythm.",
                    color_direction="steel blue, pale amber, restrained contrast",
                    camera_distance="1.5 m, medium close",
                    lighting_tip="overhead spill, soft on brow and cheek",
                    reference_film_mood="lonely metropolitan calm",
                    cinema_reference={
                        "film_title": "Lost in Translation",
                        "director": "Sofia Coppola",
                        "scene_anchor": "Hotel-window stillness before the city wakes.",
                        "why_it_connects": "Cool transit light and reflective surfaces create the same suspended urban solitude.",
                        "borrowed_technique": "Let negative space and a softened gaze carry the mood rather than overt action.",
                    },
                ),
                Recommendation(
                    style="Subdued Platform Romance",
                    why_this_matches="The clean linear background supports a softer, more intimate cinematic read than the other two.",
                    director_note="Photograph the pause before the confession, not the confession itself.",
                    emotional_goal="Tender anticipation under restraint.",
                    pose="Hands relaxed near coat pockets, look past camera.",
                    composition="Mid-torso, subject on left third, receding rails behind.",
                    color_direction="subdued navy, warm skin, softened whites",
                    camera_distance="2 m, medium shot",
                    lighting_tip="brighter overhead patch, background slightly darker",
                    reference_film_mood="tender city-night melancholy",
                    cinema_reference={
                        "film_title": "Brief Encounter",
                        "director": "David Lean",
                        "scene_anchor": "Station-platform hesitation charged by distance.",
                        "why_it_connects": "The platform setting naturally echoes a restrained romantic separation.",
                        "borrowed_technique": "Use sidelong glances and shared space to suggest feeling without explicit contact.",
                    },
                ),
                Recommendation(
                    style="Architectural Solitude",
                    why_this_matches="Repetition in the environment isolates the subject with symmetry, distinct from the other two.",
                    director_note="Make the architecture feel like it is quietly judging the character.",
                    emotional_goal="Controlled tension inside formal symmetry.",
                    pose="Square stance, shoulders loose, eyes level.",
                    composition="Centered body, platform lines pull the eye inward.",
                    color_direction="cool grays, small warm skin accent",
                    camera_distance="3 m, wide medium",
                    lighting_tip="expose for face, far platform lights bloom",
                    reference_film_mood="controlled modern noir",
                    cinema_reference={
                        "film_title": "The Conformist",
                        "director": "Bernardo Bertolucci",
                        "scene_anchor": "Figure pinned inside severe architectural lines.",
                        "why_it_connects": "The repeating geometry turns the background into a compositional instrument.",
                        "borrowed_technique": "Use symmetry and measured distance to make the subject feel emotionally trapped.",
                    },
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
    assert payload["recommendations"][0]["cinema_reference"]["film_title"] == "Lost in Translation"
    assert "director_note" in payload["recommendations"][0]
