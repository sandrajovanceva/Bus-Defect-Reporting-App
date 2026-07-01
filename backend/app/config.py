"""Application configuration, read from environment variables / .env file."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Security — MUST be overridden in production.
    secret_key: str = "dev-secret-change-me"
    access_token_expire_minutes: int = 60 * 24 * 7  # one week

    # Database. SQLite for local dev; a postgresql:// URL in Docker/production.
    database_url: str = "sqlite:///./bus_defects.db"

    # CORS: "*" for dev, or a comma-separated list of allowed origins in prod.
    allowed_origins: str = "*"

    # Account policy.
    min_password_length: int = 8

    # First dispatcher, created on startup only if the user table is empty, so
    # there is always an account to sign in with and manage the rest.
    bootstrap_admin_email: str = "admin@jsp.mk"
    bootstrap_admin_password: str = "ChangeMe123!"
    bootstrap_admin_name: str = "JSP Admin"

    @property
    def origins_list(self) -> list[str]:
        value = self.allowed_origins.strip()
        if value == "*":
            return ["*"]
        return [o.strip() for o in value.split(",") if o.strip()]

    @property
    def is_secret_insecure(self) -> bool:
        return self.secret_key == "dev-secret-change-me"


settings = Settings()
