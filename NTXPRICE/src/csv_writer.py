from __future__ import annotations

from .models import ItemState, MatchStatus
from .utils import atomic_write_csv


def write_failed_matches(path: str, items: list[ItemState]) -> int:
    rows = []
    for i in items:
        if i.match.status in {MatchStatus.UNMATCHED, MatchStatus.AMBIGUOUS, MatchStatus.ERROR}:
            rows.append({
                "sku": i.inventory.sku,
                "card_name": i.inventory.card_name,
                "set_name": i.inventory.set_name,
                "reason": i.match.notes,
                "status": i.match.status.value,
                "candidates": "; ".join(f"{c.product_id}:{c.product_name}" for c in i.match.candidates),
            })
    atomic_write_csv(path, ["sku", "card_name", "set_name", "reason", "status", "candidates"], rows)
    return len(rows)


def write_site_import(path: str, items: list[ItemState], include_out_of_stock: bool, only_changed: bool, only_approved: bool) -> int:
    rows = []
    for i in items:
        if not i.decision or not i.price:
            continue
        if (not include_out_of_stock) and (not i.inventory.in_stock):
            continue
        if only_changed and not i.decision.changed:
            continue
        if only_approved and not i.match.approved:
            continue
        rows.append({
            "sku": i.inventory.sku,
            "card_name": i.inventory.card_name,
            "quantity": i.inventory.quantity,
            "current_price": i.inventory.current_price,
            "latest_market_price": i.price.market_price,
            "pricing_basis": i.decision.pricing_basis.value,
            "new_price": i.decision.new_price,
            "absolute_change": i.decision.absolute_change,
            "percent_change": i.decision.percent_change,
            "price_changed": i.decision.changed,
            "tcgplayer_product_id": i.match.product_id,
            "tcgplayer_sku_id": i.match.sku_id,
            "source": i.price.source,
            "last_checked": i.price.lookup_timestamp.isoformat(),
            "notes": i.match.notes,
        })

    fields = [
        "sku", "card_name", "quantity", "current_price", "latest_market_price", "pricing_basis", "new_price",
        "absolute_change", "percent_change", "price_changed", "tcgplayer_product_id", "tcgplayer_sku_id", "source", "last_checked", "notes"
    ]
    atomic_write_csv(path, fields, rows)
    return len(rows)
