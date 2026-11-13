from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

import requests
import structlog
from tenacity import retry, stop_after_attempt, wait_fixed

LOGGER = structlog.get_logger(__name__)
CONNECT_URL = os.getenv("DEBEZIUM_CONNECT_URL", "http://localhost:8083")
CONNECTOR_CONFIG = Path("infra/debezium/postgres-connector.json")


@retry(stop=stop_after_attempt(30), wait=wait_fixed(2))
def _connect(method: str, path: str, **kwargs: Any) -> requests.Response:
    response = requests.request(method, f"{CONNECT_URL}{path}", timeout=10, **kwargs)
    if response.status_code >= 500:
        response.raise_for_status()
    return response


def register_connector() -> None:
    payload = json.loads(CONNECTOR_CONFIG.read_text(encoding="utf-8"))
    name = payload["name"]
    LOGGER.info("registering_debezium_connector", connector=name, connect_url=CONNECT_URL)

    existing = _connect("GET", f"/connectors/{name}")
    if existing.status_code == 200:
        config_response = _connect("PUT", f"/connectors/{name}/config", json=payload["config"])
        config_response.raise_for_status()
        LOGGER.info("updated_debezium_connector", connector=name)
        return

    response = _connect("POST", "/connectors", json=payload)
    if response.status_code not in {200, 201, 202}:
        raise RuntimeError(f"Failed to register connector: HTTP {response.status_code} {response.text}")
    LOGGER.info("created_debezium_connector", connector=name)


if __name__ == "__main__":
    register_connector()
