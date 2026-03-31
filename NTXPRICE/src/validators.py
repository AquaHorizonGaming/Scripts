from __future__ import annotations

from decimal import Decimal, InvalidOperation
import re

REQUIRED_COLUMNS = {
    "sku",
    "card_name",
    "set_name",
    "card_number",
    "rarity",
    "finish",
    "language",
    "quantity",
    "current_price",
}


def validate_columns(columns: list[str]) -> list[str]:
    missing = sorted(REQUIRED_COLUMNS - set(columns))
    return [f"Missing required column: {c}" for c in missing]


def parse_int(value: str, field: str) -> tuple[int | None, str | None]:
    try:
        return int(value), None
    except (TypeError, ValueError):
        return None, f"Invalid integer for {field}: {value}"


def parse_decimal(value: str, field: str) -> tuple[Decimal | None, str | None]:
    try:
        return Decimal(str(value)), None
    except (InvalidOperation, TypeError, ValueError):
        return None, f"Invalid decimal for {field}: {value}"


def parse_optional_int(value: str | None, field: str) -> tuple[int | None, str | None]:
    if not value:
        return None, None
    return parse_int(value, field)


def validate_tcg_url(url: str | None) -> str | None:
    if not url:
        return None
    if "tcgplayer.com" not in url:
        return f"Malformed tcgplayer_url: {url}"
    return None


def parse_id_from_url(url: str) -> tuple[int | None, int | None]:
    product = re.search(r"/product/(\d+)", url)
    sku = re.search(r"(?:sku|conditionId)=(\d+)", url)
    return (int(product.group(1)) if product else None, int(sku.group(1)) if sku else None)
