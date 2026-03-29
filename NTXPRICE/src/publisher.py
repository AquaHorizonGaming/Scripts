from __future__ import annotations

from dataclasses import dataclass
from .models import ItemState
from .csv_writer import write_site_import


@dataclass(slots=True)
class PublishResult:
    rows_exported: int
    dry_run: bool
    summary: str


class Publisher:
    def __init__(self, logger) -> None:
        self.logger = logger

    def validate(self, items: list[ItemState]) -> list[str]:
        errors: list[str] = []
        for item in items:
            if item.decision and item.decision.new_price is not None and item.decision.new_price < 0:
                errors.append(f"Negative price for {item.inventory.sku}")
        return errors

    def publish_csv(self, path: str, items: list[ItemState], include_out_of_stock: bool, only_changed: bool, only_approved: bool, dry_run: bool) -> PublishResult:
        issues = self.validate(items)
        if issues:
            raise ValueError("; ".join(issues))
        if dry_run:
            exportable = sum(1 for i in items if i.decision is not None)
            return PublishResult(exportable, True, f"Dry-run: {exportable} rows would be exported")

        count = write_site_import(path, items, include_out_of_stock, only_changed, only_approved)
        return PublishResult(count, False, f"Published {count} rows to CSV")
