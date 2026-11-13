from __future__ import annotations

from typing import Any

from fastapi import Depends, FastAPI, HTTPException

from api.repository import AnalyticsRepository
from common.logging import configure_logging

configure_logging()

app = FastAPI(
    title="OpenLake Commerce Analytics API",
    version="0.1.0",
    description="Serves gold-layer ecommerce metrics from Trino/Iceberg.",
)


def get_repository() -> AnalyticsRepository:
    return AnalyticsRepository()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "openlake-commerce-api"}


@app.get("/metrics/revenue/daily")
def daily_revenue(repo: AnalyticsRepository = Depends(get_repository)) -> list[dict[str, Any]]:
    return repo.daily_revenue()


@app.get("/metrics/orders/realtime")
def realtime_orders(repo: AnalyticsRepository = Depends(get_repository)) -> list[dict[str, Any]]:
    return repo.realtime_orders()


@app.get("/customers/{customer_id}/profile")
def customer_profile(
    customer_id: str, repo: AnalyticsRepository = Depends(get_repository)
) -> dict[str, Any]:
    try:
        return repo.customer_profile(customer_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@app.get("/campaigns/performance")
def campaign_performance(repo: AnalyticsRepository = Depends(get_repository)) -> list[dict[str, Any]]:
    return repo.campaign_performance()


@app.get("/inventory/risk")
def inventory_risk(repo: AnalyticsRepository = Depends(get_repository)) -> list[dict[str, Any]]:
    return repo.inventory_risk()
