from __future__ import annotations

import csv
from decimal import Decimal
from pathlib import Path
from .models import InventoryRow
from .validators import (
    validate_columns,
    parse_int,
    parse_decimal,
    parse_optional_int,
    validate_tcg_url,
)


def load_inventory(path: str) -> tuple[list[InventoryRow], list[str]]:
    p = Path(path)
    if not p.exists():
        return [], [f"Inventory file not found: {path}"]

    with p.open("r", newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        errors = validate_columns(reader.fieldnames or [])
        rows: list[InventoryRow] = []
        seen_skus: set[str] = set()

        for idx, raw in enumerate(reader, start=2):
            sku = (raw.get("sku") or "").strip()
            card_name = (raw.get("card_name") or "").strip()
            qty, qty_err = parse_int((raw.get("quantity") or "").strip(), "quantity")
            cur, cur_err = parse_decimal((raw.get("current_price") or "").strip(), "current_price")
            product_id, pid_err = parse_optional_int((raw.get("tcgplayer_product_id") or "").strip(), "tcgplayer_product_id")
            sku_id, sid_err = parse_optional_int((raw.get("tcgplayer_sku_id") or raw.get("product_condition_id") or "").strip(), "tcgplayer_sku_id")

            inv = InventoryRow(
                row_number=idx,
                sku=sku,
                card_name=card_name,
                set_name=(raw.get("set_name") or "").strip(),
                card_number=(raw.get("card_number") or "").strip(),
                rarity=(raw.get("rarity") or "").strip(),
                finish=(raw.get("finish") or "").strip(),
                language=(raw.get("language") or "").strip(),
                quantity=qty if qty is not None else 0,
                current_price=cur if cur is not None else Decimal("0"),
                tcgplayer_product_id=product_id,
                tcgplayer_sku_id=sku_id,
                tcgplayer_url=(raw.get("tcgplayer_url") or "").strip() or None,
                category=(raw.get("category") or "").strip() or None,
                notes=(raw.get("notes") or "").strip() or None,
                raw_data=raw,
            )

            if not card_name:
                inv.validation_errors.append("Blank card_name")
            for e in [qty_err, cur_err, pid_err, sid_err, validate_tcg_url(inv.tcgplayer_url)]:
                if e:
                    inv.validation_errors.append(e)
            if sku in seen_skus:
                inv.validation_errors.append(f"Duplicate SKU: {sku}")
            seen_skus.add(sku)
            rows.append(inv)

    return rows, errors
