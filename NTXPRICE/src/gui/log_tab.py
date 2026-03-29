from __future__ import annotations

from PySide6.QtWidgets import QWidget, QVBoxLayout, QTextEdit


class LogTab(QWidget):
    def __init__(self) -> None:
        super().__init__()
        layout = QVBoxLayout(self)
        self.text = QTextEdit()
        self.text.setReadOnly(True)
        layout.addWidget(self.text)

    def append(self, message: str) -> None:
        self.text.append(message)
