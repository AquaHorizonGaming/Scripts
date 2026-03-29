from __future__ import annotations

import csv
from datetime import datetime
from pathlib import Path
from .models import ItemState


HISTORY_FIELDS = [
    "lookup_date","lookup_timestamp","sku","card_name","set_name","card_number","finish","quantity","current_price",
    "pricing_basis","market_price","low_price","mid_price","high_price","suggested_site_price","tcgplayer_product_id",
    "tcgplayer_sku_id","source","match_method","lookup_status","notes"
]


class HistoryStore:
    def __init__(self, path: str, logger) -> None:
        self.path = Path(path)
        self.logger = logger
        self.path.parent.mkdir(parents=True, exist_ok=True)

    def append_daily(self, items: list[ItemState], force: bool = False) -> int:
        existing: set[tuple[str, str]] = set()
        if self.path.exists():
            with self.path.open("r", newline="", encoding="utf-8") as f:
                for row in csv.DictReader(f):
                    existing.add((row.get("lookup_date", ""), row.get("sku", "")))

        rows_to_add: list[dict] = []
        today = datetime.utcnow().date().isoformat()
        for item in items:
            if not item.price or not item.decision:
                continue
            key = (today, item.inventory.sku)
            if key in existing and not force:
                self.logger.info("duplicate_history_suppressed sku=%s date=%s", item.inventory.sku, today)
                continue
            rows_to_add.append({
                "lookup_date": today,
                "lookup_timestamp": item.price.lookup_timestamp.isoformat(),
                "sku": item.inventory.sku,
                "card_name": item.inventory.card_name,
                "set_name": item.inventory.set_name,
                "card_number": item.inventory.card_number,
                "finish": item.inventory.finish,
                "quantity": item.inventory.quantity,
                "current_price": item.inventory.current_price,
                "pricing_basis": item.decision.pricing_basis.value,
                "market_price": item.price.market_price,
                "low_price": item.price.low_price,
                "mid_price": item.price.mid_price,
                "high_price": item.price.high_price,
                "suggested_site_price": item.decision.new_price,
                "tcgplayer_product_id": item.match.product_id,
                "tcgplayer_sku_id": item.match.sku_id,
                "source": item.price.source,
                "match_method": item.match.method,
                "lookup_status": item.price.lookup_status,
                "notes": item.match.notes or "",
            })

        write_header = not self.path.exists()
        with self.path.open("a", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=HISTORY_FIELDS)
            if write_header:
                writer.writeheader()
            writer.writerows(rows_to_add)
        return len(rows_to_add)
