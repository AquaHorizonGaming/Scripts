from __future__ import annotations

from PySide6.QtWidgets import QWidget, QVBoxLayout, QPushButton, QFileDialog, QLabel


class InventoryTab(QWidget):
    def __init__(self, on_load) -> None:
        super().__init__()
        self.on_load = on_load
        layout = QVBoxLayout(self)
        self.label = QLabel("Load inventory CSV to begin.")
        btn = QPushButton("Load Inventory CSV")
        btn.clicked.connect(self.pick_file)
        layout.addWidget(self.label)
        layout.addWidget(btn)

    def pick_file(self) -> None:
        path, _ = QFileDialog.getOpenFileName(self, "Inventory CSV", "", "CSV Files (*.csv)")
        if path:
            self.label.setText(path)
            self.on_load(path)
