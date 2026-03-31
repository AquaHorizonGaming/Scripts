from __future__ import annotations

from PySide6.QtWidgets import QWidget, QFormLayout, QDoubleSpinBox, QComboBox


class SettingsTab(QWidget):
    def __init__(self, config) -> None:
        super().__init__()
        layout = QFormLayout(self)

        self.undercut = QDoubleSpinBox()
        self.undercut.setDecimals(2)
        self.undercut.setValue(config.undercut_amount)
        self.undercut.setSingleStep(0.01)

        self.basis = QComboBox()
        self.basis.addItems(["market_price", "mid_price", "low_price", "custom_rule"])
        self.basis.setCurrentText(config.pricing_basis)

        layout.addRow("Undercut Amount", self.undercut)
        layout.addRow("Pricing Basis", self.basis)
