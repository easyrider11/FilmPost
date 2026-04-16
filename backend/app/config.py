from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    openai_api_key: str | None = Field(default=None, alias="OPENAI_API_KEY")
    openai_model: str = Field(default="gpt-4o-mini", alias="OPENAI_MODEL")
    max_upload_bytes: int = Field(default=8 * 1024 * 1024, alias="FILMPOST_MAX_UPLOAD_BYTES")
    # Default to loopback only so a dev server isn't accidentally reachable
    # from arbitrary origins. Override via FILMPOST_CORS_ORIGINS for staging/prod.
    cors_origins: list[str] = Field(
        default_factory=lambda: [
            "http://localhost",
            "http://localhost:3000",
            "http://127.0.0.1",
            "http://127.0.0.1:3000",
        ],
        alias="FILMPOST_CORS_ORIGINS",
    )

    # --- Cost & latency guardrails for the OpenAI call ---
    # Hard wall-clock cap so a hung OpenAI request can't tie up a worker
    # forever. The vision-parse round-trip is normally 6–14s; 30s gives
    # headroom for cold paths without letting a stall block the queue.
    analysis_timeout_seconds: float = Field(
        default=30.0, alias="FILMPOST_ANALYSIS_TIMEOUT_SECONDS"
    )
    # Output ceiling so a runaway model can't blow the per-request bill.
    # ~1200 tokens comfortably covers three rich recommendation cards
    # (the response schema enforces shape, but tokens are the cost lever).
    analysis_max_output_tokens: int = Field(
        default=1200, alias="FILMPOST_ANALYSIS_MAX_OUTPUT_TOKENS"
    )

    # --- Per-IP rate limiting on /v1/analyze ---
    # `slowapi` accepts compound limit strings like "10/minute;100/day".
    # Keep the per-minute burst small (anti-abuse) and the daily ceiling
    # generous enough for a real shoot session.
    rate_limit_per_minute: str = Field(default="10/minute", alias="FILMPOST_RATE_LIMIT_PER_MINUTE")
    rate_limit_per_day: str = Field(default="100/day", alias="FILMPOST_RATE_LIMIT_PER_DAY")
    rate_limit_enabled: bool = Field(default=True, alias="FILMPOST_RATE_LIMIT_ENABLED")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
