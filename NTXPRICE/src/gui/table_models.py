from __future__ import annotations

from PySide6.QtCore import QAbstractTableModel, QModelIndex, Qt
from ..models import ItemState


COLUMNS = [
    "sku", "card_name", "set_name", "quantity", "current_price", "match_status", "match_method", "tcgplayer_product_id",
    "tcgplayer_sku_id", "matched_product_name", "pricing_basis", "market_price", "low_price", "mid_price", "high_price",
    "proposed_price", "price_changed", "notes", "last_checked"
]


class InventoryTableModel(QAbstractTableModel):
    def __init__(self) -> None:
        super().__init__()
        self.items: list[ItemState] = []

    def set_items(self, items: list[ItemState]) -> None:
        self.beginResetModel()
        self.items = items
        self.endResetModel()

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: N802
        return len(self.items)

    def columnCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: N802
        return len(COLUMNS)

    def headerData(self, section: int, orientation: Qt.Orientation, role: int = Qt.DisplayRole):
        if role != Qt.DisplayRole:
            return None
        if orientation == Qt.Horizontal:
            return COLUMNS[section]
        return section + 1

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or role not in (Qt.DisplayRole, Qt.EditRole):
            return None
        item = self.items[index.row()]
        col = COLUMNS[index.column()]
        inv = item.inventory
        mapping = {
            "sku": inv.sku,
            "card_name": inv.card_name,
            "set_name": inv.set_name,
            "quantity": inv.quantity,
            "current_price": str(inv.current_price),
            "match_status": item.match.status.value,
            "match_method": item.match.method,
            "tcgplayer_product_id": item.match.product_id,
            "tcgplayer_sku_id": item.match.sku_id,
            "matched_product_name": item.match.product_name,
            "pricing_basis": item.decision.pricing_basis.value if item.decision else "",
            "market_price": str(item.price.market_price) if item.price and item.price.market_price is not None else "",
            "low_price": str(item.price.low_price) if item.price and item.price.low_price is not None else "",
            "mid_price": str(item.price.mid_price) if item.price and item.price.mid_price is not None else "",
            "high_price": str(item.price.high_price) if item.price and item.price.high_price is not None else "",
            "proposed_price": str(item.decision.new_price) if item.decision and item.decision.new_price is not None else "",
            "price_changed": item.decision.changed if item.decision else False,
            "notes": (item.match.notes or "") + (" | " + "; ".join(inv.validation_errors) if inv.validation_errors else ""),
            "last_checked": item.price.lookup_timestamp.isoformat() if item.price else "",
        }
        return mapping.get(col, "")
