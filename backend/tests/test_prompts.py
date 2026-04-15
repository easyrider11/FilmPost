from app.prompts import ANALYSIS_SYSTEM_PROMPT, build_user_prompt


def test_system_prompt_frames_filmpost_as_coaching_not_filters() -> None:
    assert "not a filter app" in ANALYSIS_SYSTEM_PROMPT.lower()
    assert "camera distance" in ANALYSIS_SYSTEM_PROMPT.lower()
    assert "lighting tip" in ANALYSIS_SYSTEM_PROMPT.lower()


def test_user_prompt_mentions_both_images_and_required_fields() -> None:
    prompt = build_user_prompt()

    assert "subject / portrait image" in prompt.lower()
    assert "background / environment image" in prompt.lower()
    assert "exactly 3 recommendations" in prompt.lower()

    for field_name in [
        "style",
        "why_this_matches",
        "pose",
        "composition",
        "color_direction",
        "camera_distance",
        "lighting_tip",
        "reference_film_mood",
    ]:
        assert field_name in prompt
