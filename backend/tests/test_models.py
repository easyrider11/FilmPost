import pytest
from pydantic import ValidationError

from app.models import AnalysisResponse, Recommendation


def make_recommendation(style: str) -> Recommendation:
    return Recommendation(
        style=style,
        why_this_matches="Soft window light and long lines already support a restrained, intimate frame.",
        director_note="Play this as a held breath: keep the body still, then let the eyes arrive a beat late.",
        emotional_goal="Quiet ache with controlled intimacy.",
        pose="Angle the lead shoulder toward camera, hand near jacket seam.",
        composition="Subject one step off center, doorway edge as natural frame.",
        color_direction="muted olive, honey tones, lowered highlights",
        camera_distance="1.5 m, medium close",
        lighting_tip="soft side light, shadow cheek visible",
        reference_film_mood="Quiet urban longing",
        cinema_reference={
            "film_title": "In the Mood for Love",
            "director": "Wong Kar-wai",
            "scene_anchor": "Hallway pause beneath warm practical light.",
            "why_it_connects": "Tight architecture and hushed warm tones make the background feel similarly intimate.",
            "borrowed_technique": "Use doorway edges and lingering stillness to turn proximity into tension.",
        },
    )


def test_analysis_response_requires_exactly_three_recommendations() -> None:
    with pytest.raises(ValidationError):
        AnalysisResponse(
            context_summary="Covered arcade with soft daylight and architectural depth.",
            recommendations=[
                make_recommendation("Quiet Arcade"),
                make_recommendation("Silver Window Portrait"),
            ],
        )


def test_analysis_response_trims_content() -> None:
    response = AnalysisResponse(
        context_summary="  Warm dusk courtyard with reflective stone and calm depth.  ",
        recommendations=[
            make_recommendation("Golden Walk"),
            make_recommendation("Soft Balcony"),
            make_recommendation("Amber Threshold"),
        ],
    )

    assert response.context_summary == "Warm dusk courtyard with reflective stone and calm depth."
    assert response.recommendations[0].style == "Golden Walk"
    assert response.recommendations[0].cinema_reference.film_title == "In the Mood for Love"
