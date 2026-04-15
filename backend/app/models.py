from pydantic import BaseModel, ConfigDict, Field, field_validator


class Recommendation(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    style: str = Field(min_length=2, max_length=60)
    why_this_matches: str = Field(min_length=12, max_length=180)
    pose: str = Field(min_length=6, max_length=90)
    composition: str = Field(min_length=6, max_length=90)
    color_direction: str = Field(min_length=4, max_length=60)
    camera_distance: str = Field(min_length=4, max_length=40)
    lighting_tip: str = Field(min_length=6, max_length=80)
    reference_film_mood: str = Field(min_length=4, max_length=50)


class AnalysisResponse(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    context_summary: str = Field(min_length=12, max_length=320)
    recommendations: list[Recommendation]

    @field_validator("recommendations")
    @classmethod
    def validate_recommendation_count(cls, value: list[Recommendation]) -> list[Recommendation]:
        if len(value) != 3:
            raise ValueError("FilmPost requires exactly 3 recommendations.")
        return value
