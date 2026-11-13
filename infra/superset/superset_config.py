SECRET_KEY = "change-me-for-local-dev"
SQLALCHEMY_DATABASE_URI = "sqlite:////app/superset_home/superset.db"
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "DASHBOARD_RBAC": True,
}
