from __future__ import annotations

from PySide6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QLabel


class MatchReviewTab(QWidget):
    def __init__(self, on_auto_match) -> None:
        super().__init__()
        layout = QVBoxLayout(self)
        self.summary = QLabel("Run matching to review matched/unmatched/ambiguous items.")
        btn = QPushButton("Run Matching")
        btn.clicked.connect(on_auto_match)
        layout.addWidget(self.summary)
        layout.addWidget(btn)
