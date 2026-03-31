from __future__ import annotations

import sqlite3
from pathlib import Path
from datetime import datetime


class CacheStore:
    def __init__(self, db_path: str) -> None:
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        self.conn = sqlite3.connect(db_path)
        self._init_schema()

    def _init_schema(self) -> None:
        cur = self.conn.cursor()
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS pricing_cache (
              key TEXT PRIMARY KEY,
              market_price TEXT,
              low_price TEXT,
              mid_price TEXT,
              high_price TEXT,
              source TEXT,
              lookup_timestamp TEXT
            )
            """
        )
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS manual_overrides (
              sku TEXT PRIMARY KEY,
              product_id INTEGER,
              sku_id INTEGER,
              do_not_update INTEGER DEFAULT 0,
              updated_at TEXT
            )
            """
        )
        self.conn.commit()

    def get_pricing_cache(self, key: str) -> dict | None:
        row = self.conn.execute("SELECT market_price,low_price,mid_price,high_price,source,lookup_timestamp FROM pricing_cache WHERE key=?", (key,)).fetchone()
        if not row:
            return None
        return {
            "market_price": row[0],
            "low_price": row[1],
            "mid_price": row[2],
            "high_price": row[3],
            "source": row[4],
            "lookup_timestamp": row[5],
        }

    def set_pricing_cache(self, key: str, payload: dict) -> None:
        self.conn.execute(
            "REPLACE INTO pricing_cache(key,market_price,low_price,mid_price,high_price,source,lookup_timestamp) VALUES(?,?,?,?,?,?,?)",
            (
                key,
                payload.get("market_price"),
                payload.get("low_price"),
                payload.get("mid_price"),
                payload.get("high_price"),
                payload.get("source"),
                payload.get("lookup_timestamp", datetime.utcnow().isoformat()),
            ),
        )
        self.conn.commit()

    def set_manual_override(self, sku: str, product_id: int | None, sku_id: int | None, do_not_update: bool = False) -> None:
        self.conn.execute(
            "REPLACE INTO manual_overrides(sku,product_id,sku_id,do_not_update,updated_at) VALUES(?,?,?,?,?)",
            (sku, product_id, sku_id, int(do_not_update), datetime.utcnow().isoformat()),
        )
        self.conn.commit()
