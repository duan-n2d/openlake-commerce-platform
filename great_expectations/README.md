# Great Expectations

Critical checks cover:

- Not-null and unique primary keys
- Valid order and payment status enums
- Non-negative payment amount and order total
- Referential integrity expectations documented for dbt tests
- Freshness through dbt source freshness
- Row count anomaly bounds
- Duplicate CDC event detection in bronze payloads

Run:

```bash
make ge-check
```

The checkpoint intentionally fails the pipeline when critical expectations fail.
