from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class PlatformSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    postgres_host: str = "localhost"
    postgres_port: int = 5432
    postgres_db: str = "commerce"
    postgres_user: str = "commerce_app"
    postgres_password: str = "commerce_app"

    kafka_bootstrap_servers: str = "localhost:29092"
    debezium_connect_url: str = "http://localhost:8083"

    trino_host: str = "localhost"
    trino_port: int = 8080
    trino_user: str = "openlake"
    trino_catalog: str = "iceberg"
    trino_schema: str = "gold"

    api_cache_ttl_seconds: int = 30

    @property
    def postgres_dsn(self) -> str:
        return (
            f"host={self.postgres_host} port={self.postgres_port} dbname={self.postgres_db} "
            f"user={self.postgres_user} password={self.postgres_password}"
        )
