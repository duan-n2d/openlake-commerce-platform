from __future__ import annotations

import os
from typing import Any

import requests
from requests import Response
from tenacity import retry, stop_after_attempt, wait_fixed


MANAGEMENT_URI = os.getenv("POLARIS_MANAGEMENT_URI", "http://polaris:8181/api/management")
CATALOG_NAME = os.getenv("POLARIS_CATALOG_NAME", "commerce")
WAREHOUSE = os.getenv("POLARIS_WAREHOUSE", "s3://openlake/warehouse")


@retry(stop=stop_after_attempt(20), wait=wait_fixed(3))
def _request(method: str, url: str, **kwargs: Any) -> Response:
    response = requests.request(method, url, timeout=10, **kwargs)
    if response.status_code >= 500:
        response.raise_for_status()
    return response


def bootstrap_catalog() -> None:
    """Best-effort Polaris bootstrap for local development.

    Polaris APIs have evolved quickly. This script keeps the desired catalog
    payload close to the repo and fails with a clear message when a running
    Polaris image expects a newer management shape.
    """

    payload = {
        "name": CATALOG_NAME,
        "type": "INTERNAL",
        "properties": {
            "default-base-location": WAREHOUSE,
            "s3.endpoint": os.getenv("MINIO_ENDPOINT", "http://minio:9000"),
            "s3.path-style-access": "true",
            "s3.access-key-id": os.getenv("MINIO_ROOT_USER", "minioadmin"),
            "s3.secret-access-key": os.getenv("MINIO_ROOT_PASSWORD", "minioadmin"),
            "s3.region": "us-east-1",
        },
    }
    response = _request("POST", f"{MANAGEMENT_URI}/v1/catalogs", json=payload)
    if response.status_code in {200, 201, 204, 409}:
        print(f"Polaris catalog '{CATALOG_NAME}' is ready.")
        return
    raise RuntimeError(
        f"Polaris catalog bootstrap failed: HTTP {response.status_code} {response.text}"
    )


if __name__ == "__main__":
    bootstrap_catalog()
