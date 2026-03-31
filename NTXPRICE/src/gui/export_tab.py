from __future__ import annotations

from PySide6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel


class ExportTab(QWidget):
    def __init__(self, on_export) -> None:
        super().__init__()
        layout = QVBoxLayout(self)
        self.summary = QLabel("Export validated rows and write history snapshots.")
        btn = QPushButton("Export CSV")
        btn.clicked.connect(on_export)
        layout.addWidget(self.summary)
        layout.addWidget(btn)
