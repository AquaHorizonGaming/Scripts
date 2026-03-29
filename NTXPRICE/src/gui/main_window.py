from __future__ import annotations

from PySide6.QtWidgets import (
    QApplication,
    QMainWindow,
    QWidget,
    QVBoxLayout,
    QTabWidget,
    QTableView,
    QLineEdit,
    QHBoxLayout,
    QComboBox,
    QLabel,
)
from PySide6.QtCore import QSortFilterProxyModel, Qt
from ..config import AppConfig
from ..inventory_loader import load_inventory
from ..models import ItemState
from ..logger import setup_logger
from ..config import load_env_credentials
from ..tcgplayer_provider import TCGplayerProvider
from ..matching_engine import MatchingEngine
from ..pricing_engine import PricingEngine
from ..csv_writer import write_site_import
from ..history_store import HistoryStore
from .table_models import InventoryTableModel
from .inventory_tab import InventoryTab
from .match_review_tab import MatchReviewTab
from .pricing_review_tab import PricingReviewTab
from .export_tab import ExportTab
from .settings_tab import SettingsTab
from .log_tab import LogTab
from .dialogs import info, error


class StatusFilterProxy(QSortFilterProxyModel):
    def __init__(self) -> None:
        super().__init__()
        self.query = ""
        self.status = "all"

    def setQuery(self, query: str) -> None:  # noqa: N802
        self.query = query.lower()
        self.invalidateFilter()

    def setStatus(self, status: str) -> None:  # noqa: N802
        self.status = status
        self.invalidateFilter()

    def filterAcceptsRow(self, source_row: int, source_parent) -> bool:
        model = self.sourceModel()
        sku = str(model.data(model.index(source_row, 0), Qt.DisplayRole) or "").lower()
        card = str(model.data(model.index(source_row, 1), Qt.DisplayRole) or "").lower()
        set_name = str(model.data(model.index(source_row, 2), Qt.DisplayRole) or "").lower()
        status = str(model.data(model.index(source_row, 5), Qt.DisplayRole) or "").lower()
        changed = str(model.data(model.index(source_row, 16), Qt.DisplayRole) or "").lower()
        qty = int(model.data(model.index(source_row, 3), Qt.DisplayRole) or 0)

        text_ok = self.query in sku or self.query in card or self.query in set_name
        if self.status == "all":
            status_ok = True
        elif self.status == "changed":
            status_ok = changed == "true"
        elif self.status == "unchanged":
            status_ok = changed in {"false", ""}
        elif self.status == "in stock":
            status_ok = qty > 0
        elif self.status == "out of stock":
            status_ok = qty <= 0
        else:
            status_ok = status == self.status
        return text_ok and status_ok


class MainWindow(QMainWindow):
    def __init__(self, config: AppConfig) -> None:
        super().__init__()
        self.config = config
        self.logger = setup_logger(config.log_level)
        self.items: list[ItemState] = []
        creds = load_env_credentials()
        self.provider = TCGplayerProvider(creds["public_key"], creds["private_key"], creds["access_token"], config.request_timeout, config.retry_count, config.retry_backoff, config.sleep_between_requests)

        self.setWindowTitle(config.gui_window_title)
        central = QWidget()
        root = QVBoxLayout(central)

        top = QHBoxLayout()
        self.search = QLineEdit()
        self.search.setPlaceholderText("Search by sku/card/set")
        self.filter_box = QComboBox()
        self.filter_box.addItems(["all", "matched", "unmatched", "ambiguous", "error", "changed", "unchanged", "in stock", "out of stock"])
        self.summary = QLabel("total: 0")
        top.addWidget(self.search)
        top.addWidget(self.filter_box)
        top.addWidget(self.summary)
        root.addLayout(top)

        self.model = InventoryTableModel()
        self.proxy = StatusFilterProxy()
        self.proxy.setSourceModel(self.model)
        self.table = QTableView()
        self.table.setModel(self.proxy)
        self.table.setSortingEnabled(True)
        root.addWidget(self.table)

        self.tabs = QTabWidget()
        self.log_tab = LogTab()
        self.inventory_tab = InventoryTab(self.load_inventory)
        self.match_tab = MatchReviewTab(self.run_match)
        self.pricing_tab = PricingReviewTab(self.run_pricing)
        self.export_tab = ExportTab(self.export)
        self.settings_tab = SettingsTab(config)
        self.tabs.addTab(self.inventory_tab, "Inventory Import")
        self.tabs.addTab(self.match_tab, "Match Review")
        self.tabs.addTab(self.pricing_tab, "Pricing Review")
        self.tabs.addTab(self.export_tab, "Export / History")
        self.tabs.addTab(self.settings_tab, "Settings / Config")
        self.tabs.addTab(self.log_tab, "Run Log / Diagnostics")
        root.addWidget(self.tabs)

        self.setCentralWidget(central)
        self.search.textChanged.connect(self.proxy.setQuery)
        self.filter_box.currentTextChanged.connect(self.proxy.setStatus)

    def _refresh(self) -> None:
        self.model.set_items(self.items)
        total = len(self.items)
        matched = len([i for i in self.items if i.match.status.value == "matched"])
        ambiguous = len([i for i in self.items if i.match.status.value == "ambiguous"])
        changed = len([i for i in self.items if i.decision and i.decision.changed])
        self.summary.setText(f"total: {total} matched: {matched} ambiguous: {ambiguous} changed: {changed}")

    def load_inventory(self, path: str) -> None:
        rows, errors = load_inventory(path)
        self.items = [ItemState(inventory=r) for r in rows]
        for e in errors:
            self.log_tab.append(f"ERROR: {e}")
        self._refresh()
        info(self, "Inventory", f"Loaded {len(self.items)} rows")

    def run_match(self) -> None:
        m = MatchingEngine(self.provider, self.logger, include_out_of_stock=self.config.include_out_of_stock)
        m.run(self.items)
        self._refresh()
        self.log_tab.append("Matching completed")

    def run_pricing(self) -> None:
        self.config.undercut_amount = self.settings_tab.undercut.value()
        self.config.pricing_basis = self.settings_tab.basis.currentText()
        p = PricingEngine(self.provider, self.logger, pricing_basis=self.config.pricing_basis, undercut_amount=self.config.undercut_amount, min_price=self.config.min_price, max_price=self.config.max_price, fallback_to_current_price=self.config.fallback_to_current_price, skip_if_no_market_price=self.config.skip_if_no_market_price, minimum_change_threshold=self.config.minimum_change_threshold)
        p.run(self.items)
        self._refresh()
        self.log_tab.append("Pricing completed")

    def export(self) -> None:
        try:
            count = write_site_import(self.config.site_import_csv_path, self.items, self.config.include_out_of_stock, self.config.only_changed_export, self.config.only_approved_export)
            HistoryStore(self.config.history_csv_path, self.logger).append_daily(self.items)
            info(self, "Export", f"Exported {count} rows")
            self.log_tab.append(f"Exported {count} rows")
        except Exception as exc:
            error(self, "Export Error", str(exc))


def run_gui(config: AppConfig) -> None:
    app = QApplication([])
    w = MainWindow(config)
    w.resize(1400, 900)
    w.show()
    app.exec()
