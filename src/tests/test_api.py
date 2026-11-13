from __future__ import annotations

from fastapi.testclient import TestClient

from api.main import app, get_repository


class FakeRepository:
    def daily_revenue(self) -> list[dict[str, object]]:
        return [{"order_date": "2026-07-01", "gross_revenue": "100.00"}]

    def realtime_orders(self) -> list[dict[str, object]]:
        return [{"metric_minute": "2026-07-01T10:00:00Z", "order_count": 3}]

    def customer_profile(self, customer_id: str) -> dict[str, object]:
        return {"customer_id": customer_id, "lifetime_revenue": "250.00"}

    def campaign_performance(self) -> list[dict[str, object]]:
        return [{"campaign_code": "SUMMER26_EMAIL", "conversion_rate": 0.12}]

    def inventory_risk(self) -> list[dict[str, object]]:
        return [{"sku": "SP-YGA-310", "risk_level": "critical"}]


def test_health_endpoint() -> None:
    client = TestClient(app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_metrics_endpoint_uses_repository_override() -> None:
    app.dependency_overrides[get_repository] = lambda: FakeRepository()
    client = TestClient(app)
    response = client.get("/metrics/revenue/daily")
    assert response.status_code == 200
    assert response.json()[0]["gross_revenue"] == "100.00"
    app.dependency_overrides.clear()
