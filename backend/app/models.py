from pydantic import BaseModel, ConfigDict, Field, field_validator


class CinemaReference(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    film_title: str = Field(min_length=2, max_length=60)
    director: str = Field(min_length=2, max_length=40)
    scene_anchor: str = Field(min_length=8, max_length=80)
    why_it_connects: str = Field(min_length=12, max_length=180)
    borrowed_technique: str = Field(min_length=10, max_length=120)


class Recommendation(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    style: str = Field(min_length=2, max_length=60)
    why_this_matches: str = Field(min_length=12, max_length=180)
    director_note: str = Field(min_length=18, max_length=220)
    emotional_goal: str = Field(min_length=8, max_length=80)
    pose: str = Field(min_length=6, max_length=90)
    composition: str = Field(min_length=6, max_length=90)
    color_direction: str = Field(min_length=4, max_length=60)
    camera_distance: str = Field(min_length=4, max_length=40)
    lighting_tip: str = Field(min_length=6, max_length=80)
    reference_film_mood: str = Field(min_length=4, max_length=50)
    cinema_reference: CinemaReference


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
