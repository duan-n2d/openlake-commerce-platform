from __future__ import annotations

import os
from dataclasses import dataclass

import psycopg
import structlog
from tenacity import retry, stop_after_attempt, wait_fixed

LOGGER = structlog.get_logger(__name__)


@dataclass(frozen=True)
class PostgresSettings:
    host: str = os.getenv("POSTGRES_HOST", "localhost")
    port: int = int(os.getenv("POSTGRES_PORT", "5432"))
    dbname: str = os.getenv("POSTGRES_DB", "commerce")
    user: str = os.getenv("POSTGRES_USER", "commerce_app")
    password: str = os.getenv("POSTGRES_PASSWORD", "commerce_app")

    @property
    def dsn(self) -> str:
        return (
            f"host={self.host} port={self.port} dbname={self.dbname} "
            f"user={self.user} password={self.password}"
        )


@retry(stop=stop_after_attempt(20), wait=wait_fixed(2))
def _connect(settings: PostgresSettings) -> psycopg.Connection:
    return psycopg.connect(settings.dsn)


def main() -> None:
    settings = PostgresSettings()
    with _connect(settings) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    (SELECT count(*) FROM commerce.customers) AS customers,
                    (SELECT count(*) FROM commerce.products) AS products,
                    (SELECT count(*) FROM commerce.orders) AS orders,
                    (SELECT count(*) FROM commerce.payments) AS payments
                """
            )
            row = cur.fetchone()
    LOGGER.info(
        "postgres_seed_ready",
        customers=row[0],
        products=row[1],
        orders=row[2],
        payments=row[3],
    )


if __name__ == "__main__":
    main()
