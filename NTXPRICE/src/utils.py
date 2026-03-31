from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
import csv
import tempfile
import os


def d(value: float | str | Decimal | None) -> Decimal | None:
    if value is None or value == "":
        return None
    return Decimal(str(value))


def quantize_price(value: Decimal) -> Decimal:
    return value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def atomic_write_csv(path: str, fieldnames: list[str], rows: list[dict]) -> None:
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix="ntxprice_", suffix=".csv", dir=str(p.parent))
    os.close(fd)
    try:
        with open(temp, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)
        os.replace(temp, p)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)
