from __future__ import annotations

from datetime import datetime, timezone
from .config import AppConfig, load_env_credentials
from .logger import setup_logger
from .models import ItemState, RunResult
from .inventory_loader import load_inventory
from .tcgplayer_provider import TCGplayerProvider
from .matching_engine import MatchingEngine
from .pricing_engine import PricingEngine
from .cache_store import CacheStore
from .history_store import HistoryStore
from .csv_writer import write_failed_matches
from .publisher import Publisher
from .services import MetricsService


def run_daily_sync(config: AppConfig, input_path: str | None = None, force: bool = False, sku_filter: str | None = None) -> RunResult:
    logger = setup_logger(config.log_level)
    started = datetime.now(timezone.utc)
    credentials = load_env_credentials()
    if not credentials["access_token"]:
        logger.warning("No access token in env; API requests may fail")

    provider = TCGplayerProvider(
        credentials["public_key"],
        credentials["private_key"],
        credentials["access_token"],
        timeout=config.request_timeout,
        retry_count=config.retry_count,
        retry_backoff=config.retry_backoff,
        sleep_between_requests=config.sleep_between_requests,
    )

    rows, import_errors = load_inventory(input_path or config.inventory_csv_path)
    items = [ItemState(inventory=r) for r in rows]
    if sku_filter:
        items = [i for i in items if i.inventory.sku == sku_filter]

    logger.info("Imported rows=%s errors=%s", len(rows), len(import_errors))
    for e in import_errors:
        logger.error(e)

    matcher = MatchingEngine(provider, logger, include_out_of_stock=config.include_out_of_stock)
    matcher.run(items)

    cache = CacheStore(config.sqlite_cache_path) if config.sqlite_cache_enabled else None
    pricer = PricingEngine(
        provider=provider,
        logger=logger,
        cache_store=cache,
        pricing_basis=config.pricing_basis,
        undercut_amount=config.undercut_amount,
        min_price=config.min_price,
        max_price=config.max_price,
        fallback_to_current_price=config.fallback_to_current_price,
        skip_if_no_market_price=config.skip_if_no_market_price,
        minimum_change_threshold=config.minimum_change_threshold,
    )
    pricer.run(items)

    history_store = HistoryStore(config.history_csv_path, logger)
    history_count = history_store.append_daily(items, force=force)
    failed_count = write_failed_matches(config.failed_matches_csv_path, items)

    publisher = Publisher(logger)
    pub = publisher.publish_csv(
        config.site_import_csv_path,
        items,
        include_out_of_stock=config.include_out_of_stock,
        only_changed=config.only_changed_export,
        only_approved=config.only_approved_export,
        dry_run=config.dry_run or config.write_mode == "dry_run",
    )
    logger.info(pub.summary)

    summary = MetricsService.summarize(items)
    ended = datetime.now(timezone.utc)
    return RunResult(
        started_at=started,
        ended_at=ended,
        summary=summary,
        output_files={
            "history": config.history_csv_path,
            "failed_matches": config.failed_matches_csv_path,
            "site_import": config.site_import_csv_path,
        },
        errors=import_errors + [f"failed_matches={failed_count}", f"history_written={history_count}"],
    )
