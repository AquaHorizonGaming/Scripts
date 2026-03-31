from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import os
import yaml
from dotenv import load_dotenv


@dataclass(slots=True)
class AppConfig:
    inventory_csv_path: str = "sample_inventory.csv"
    output_dir: str = "data"
    history_csv_path: str = "data/price_history.csv"
    failed_matches_csv_path: str = "data/failed_matches.csv"
    site_import_csv_path: str = "data/site_import.csv"
    changes_only_csv_path: str = "data/price_changes_only.csv"
    undercut_amount: float = 0.01
    min_price: float = 0.01
    max_price: float = 9999.99
    pricing_basis: str = "market_price"
    request_timeout: float = 20
    retry_count: int = 3
    retry_backoff: float = 1.5
    sleep_between_requests: float = 0.1
    log_level: str = "INFO"
    include_out_of_stock: bool = False
    fallback_to_current_price: bool = True
    skip_if_no_market_price: bool = False
    minimum_change_threshold: float = 0.0
    sqlite_cache_enabled: bool = True
    sqlite_cache_path: str = "data/ntxprice_cache.db"
    gui_window_title: str = "NTXPRICE"
    write_mode: str = "publish"
    dry_run: bool = False
    only_changed_export: bool = False
    only_approved_export: bool = False


def load_config(config_path: str | None = None) -> AppConfig:
    load_dotenv()
    cfg = AppConfig()
    if config_path:
        content = yaml.safe_load(Path(config_path).read_text(encoding="utf-8")) or {}
        for key, value in content.items():
            if hasattr(cfg, key):
                setattr(cfg, key, value)

    Path(cfg.output_dir).mkdir(parents=True, exist_ok=True)
    return cfg


def load_env_credentials() -> dict[str, str]:
    return {
        "public_key": os.getenv("TCGPLAYER_PUBLIC_KEY", ""),
        "private_key": os.getenv("TCGPLAYER_PRIVATE_KEY", ""),
        "access_token": os.getenv("TCGPLAYER_ACCESS_TOKEN", ""),
        "refresh_token": os.getenv("TCGPLAYER_REFRESH_TOKEN", ""),
    }
