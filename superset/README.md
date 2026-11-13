# Superset

Start Superset:

```bash
make superset
```

Add a Trino database connection:

```text
trino://openlake@trino:8080/iceberg/gold
```

Import `superset/dashboards/openlake_commerce_dashboard.yaml` as starter dashboard metadata. In a production setup, export dashboards from Superset after building charts interactively and commit the exported ZIP/YAML.
