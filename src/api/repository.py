from __future__ import annotations

from typing import Any

import trino
from cachetools import TTLCache, cachedmethod

from common.settings import PlatformSettings


class AnalyticsRepository:
    def __init__(self, settings: PlatformSettings | None = None) -> None:
        self.settings = settings or PlatformSettings()
        self._cache: TTLCache[str, list[dict[str, Any]]] = TTLCache(
            maxsize=128, ttl=self.settings.api_cache_ttl_seconds
        )

    def _connection(self) -> trino.dbapi.Connection:
        return trino.dbapi.connect(
            host=self.settings.trino_host,
            port=self.settings.trino_port,
            user=self.settings.trino_user,
            catalog=self.settings.trino_catalog,
            schema=self.settings.trino_schema,
        )

    @cachedmethod(lambda self: self._cache)
    def query(self, sql: str) -> list[dict[str, Any]]:
        with self._connection() as conn:
            cur = conn.cursor()
            cur.execute(sql)
            columns = [column[0] for column in cur.description]
            return [dict(zip(columns, row, strict=True)) for row in cur.fetchall()]

    def daily_revenue(self) -> list[dict[str, Any]]:
        return self.query(
            """
            SELECT order_date, gross_revenue, captured_revenue, order_count
            FROM mart_daily_revenue
            ORDER BY order_date DESC
            LIMIT 90
            """
        )

    def realtime_orders(self) -> list[dict[str, Any]]:
        return self.query(
            """
            SELECT metric_minute, order_count, gross_revenue, payment_success_rate
            FROM realtime_order_metrics
            ORDER BY metric_minute DESC
            LIMIT 60
            """
        )

    def customer_profile(self, customer_id: str) -> dict[str, Any]:
        rows = self.query(
            f"""
            SELECT *
            FROM mart_customer_360
            WHERE customer_id = '{customer_id}'
            LIMIT 1
            """
        )
        if not rows:
            raise LookupError(f"Customer {customer_id} was not found in mart_customer_360")
        return rows[0]

    def campaign_performance(self) -> list[dict[str, Any]]:
        return self.query(
            """
            SELECT campaign_code, channel, sessions, conversions, conversion_rate, attributed_revenue
            FROM mart_campaign_performance
            ORDER BY attributed_revenue DESC
            """
        )

    def inventory_risk(self) -> list[dict[str, Any]]:
        return self.query(
            """
            SELECT sku, product_name, warehouse_code, quantity_on_hand, reorder_threshold, risk_level
            FROM mart_inventory_risk
            WHERE risk_level IN ('critical', 'reorder')
            ORDER BY risk_level, quantity_on_hand
            """
        )
