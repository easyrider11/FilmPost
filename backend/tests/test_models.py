import pytest
from pydantic import ValidationError

from app.models import AnalysisResponse, Recommendation


def make_recommendation(style: str) -> Recommendation:
    return Recommendation(
        style=style,
        why_this_matches="Soft window light and long lines already support a restrained, intimate frame.",
        pose="Angle the lead shoulder toward camera, hand near jacket seam.",
        composition="Subject one step off center, doorway edge as natural frame.",
        color_direction="muted olive, honey tones, lowered highlights",
        camera_distance="1.5 m, medium close",
        lighting_tip="soft side light, shadow cheek visible",
        reference_film_mood="Quiet urban longing",
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
