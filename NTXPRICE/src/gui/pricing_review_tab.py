from __future__ import annotations

from PySide6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel


class PricingReviewTab(QWidget):
    def __init__(self, on_price) -> None:
        super().__init__()
        layout = QVBoxLayout(self)
        self.summary = QLabel("Run pricing to populate market/low/mid/high and proposed prices.")
        btn = QPushButton("Run Pricing")
        btn.clicked.connect(on_price)
        layout.addWidget(self.summary)
        layout.addWidget(btn)
