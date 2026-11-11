"""Thin helpers around PyMySQL. All SQL lives in app.py as raw, parameterised strings."""
from contextlib import contextmanager
import pymysql
from config import DB_CONFIG


def get_conn():
    return pymysql.connect(**DB_CONFIG)


def fetch_all(sql, params=None):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return cur.fetchall()
    finally:
        conn.close()


def fetch_one(sql, params=None):
    rows = fetch_all(sql, params)
    return rows[0] if rows else None


def execute(sql, params=None):
    """Run one write statement, commit, return affected row count."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            n = cur.execute(sql, params)
        conn.commit()
        return n
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


@contextmanager
def transaction():
    """Multi-statement transaction: commit on success, roll back on any error."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            yield cur
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def friendly_error(e):
    """Turn a PyMySQL error into a message a user can act on."""
    code = e.args[0] if e.args else 0
    msg = e.args[1] if len(e.args) > 1 else str(e)
    if code == 1644:      # SIGNAL SQLSTATE '45000' from our triggers
        return msg
    if code == 1062:
        return "That record already exists (duplicate value)."
    if code == 1451:
        return "Cannot delete this: other records still depend on it."
    if code == 1452:
        return "A record this refers to does not exist."
    if code == 3819:
        return f"A data rule was violated: {msg}"
    return f"Database error ({code}): {msg}"
