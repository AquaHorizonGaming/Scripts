from __future__ import annotations

import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path


def setup_logger(level: str = "INFO", log_file: str = "logs/ntxprice.log") -> logging.Logger:
    Path(log_file).parent.mkdir(parents=True, exist_ok=True)
    logger = logging.getLogger("ntxprice")
    logger.setLevel(level.upper())
    logger.handlers.clear()

    formatter = logging.Formatter(
        "%(asctime)s | %(levelname)s | %(name)s | %(message)s"
    )

    ch = logging.StreamHandler()
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    fh = RotatingFileHandler(log_file, maxBytes=2_000_000, backupCount=3)
    fh.setFormatter(formatter)
    logger.addHandler(fh)
    return logger
