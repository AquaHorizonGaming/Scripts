from __future__ import annotations

import argparse
from .config import load_config
from .app import run_daily_sync


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="NTXPRICE")
    p.add_argument("--config", default="sample_config.yaml")
    p.add_argument("--input")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--force", action="store_true")
    p.add_argument("--only-in-stock", action="store_true")
    p.add_argument("--sku")
    p.add_argument("--export-changed-only", action="store_true")
    p.add_argument("--gui", action="store_true")
    return p


def run_cli() -> int:
    args = build_parser().parse_args()
    cfg = load_config(args.config)
    if args.dry_run:
        cfg.dry_run = True
    if args.only_in_stock:
        cfg.include_out_of_stock = False
    if args.export_changed_only:
        cfg.only_changed_export = True

    if args.gui:
        from .gui.main_window import run_gui
        run_gui(cfg)
        return 0

    result = run_daily_sync(cfg, input_path=args.input, force=args.force, sku_filter=args.sku)
    print("NTXPRICE completed")
    print(result.summary)
    return 0
