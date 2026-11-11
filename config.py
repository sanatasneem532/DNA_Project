"""Configuration. Override with environment variables if needed."""
import os
import pymysql

SECRET_KEY = os.environ.get("SECRET_KEY", "dev-only-change-me")

DB_CONFIG = dict(
    host=os.environ.get("DB_HOST", "localhost"),
    port=int(os.environ.get("DB_PORT", "3306")),
    user=os.environ.get("DB_USER", "appuser"),
    password=os.environ.get("DB_PASSWORD", "your_password"),
    database=os.environ.get("DB_NAME", "speedrun_db"),
    charset="utf8mb4",
    cursorclass=pymysql.cursors.DictCursor,
    autocommit=False,
)
