from app.prompts import ANALYSIS_SYSTEM_PROMPT, build_user_prompt


def test_system_prompt_frames_filmpost_as_coaching_not_filters() -> None:
    assert "not a filter app" in ANALYSIS_SYSTEM_PROMPT.lower()
    assert "camera distance" in ANALYSIS_SYSTEM_PROMPT.lower()
    assert "lighting tip" in ANALYSIS_SYSTEM_PROMPT.lower()
    assert "director" in ANALYSIS_SYSTEM_PROMPT.lower()
    assert "classic film" in ANALYSIS_SYSTEM_PROMPT.lower()


def test_user_prompt_mentions_both_images_and_required_fields() -> None:
    prompt = build_user_prompt()

    assert "subject / portrait image" in prompt.lower()
    assert "background / environment image" in prompt.lower()
    assert "exactly 3 recommendations" in prompt.lower()

    for field_name in [
        "style",
        "why_this_matches",
        "director_note",
        "emotional_goal",
        "pose",
        "composition",
        "color_direction",
        "camera_distance",
        "lighting_tip",
        "reference_film_mood",
        "cinema_reference",
    ]:
        assert field_name in prompt


def test_user_prompt_requires_concise_context_summary() -> None:
    prompt = build_user_prompt()

    assert "context_summary" in prompt
    assert "1 sentence" in prompt
    assert "140 characters" in prompt
