from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import Any


class MatchStatus(str, Enum):
    UNMATCHED = "unmatched"
    MATCHED = "matched"
    AMBIGUOUS = "ambiguous"
    ERROR = "error"


class PricingBasis(str, Enum):
    MARKET = "market_price"
    MID = "mid_price"
    LOW = "low_price"
    CUSTOM = "custom_rule"


@dataclass(slots=True)
class InventoryRow:
    row_number: int
    sku: str
    card_name: str
    set_name: str
    card_number: str
    rarity: str
    finish: str
    language: str
    quantity: int
    current_price: Decimal
    tcgplayer_product_id: int | None = None
    tcgplayer_sku_id: int | None = None
    tcgplayer_url: str | None = None
    category: str | None = None
    notes: str | None = None
    raw_data: dict[str, Any] = field(default_factory=dict)
    validation_errors: list[str] = field(default_factory=list)

    @property
    def in_stock(self) -> bool:
        return self.quantity > 0


@dataclass(slots=True)
class MatchCandidate:
    product_id: int
    sku_id: int | None
    product_name: str
    set_name: str | None
    finish: str | None
    condition: str | None
    language: str | None
    confidence: float
    notes: str = ""


@dataclass(slots=True)
class MatchResult:
    status: MatchStatus
    method: str
    product_id: int | None = None
    sku_id: int | None = None
    product_name: str | None = None
    set_name: str | None = None
    finish: str | None = None
    condition: str | None = None
    language: str | None = None
    confidence: float = 0.0
    notes: str = ""
    candidates: list[MatchCandidate] = field(default_factory=list)
    approved: bool = True


@dataclass(slots=True)
class PriceResult:
    market_price: Decimal | None
    low_price: Decimal | None
    mid_price: Decimal | None
    high_price: Decimal | None
    finish: str | None
    source: str
    lookup_timestamp: datetime
    lookup_status: str = "ok"


@dataclass(slots=True)
class PricingDecision:
    pricing_basis: PricingBasis
    selected_value: Decimal | None
    new_price: Decimal | None
    absolute_change: Decimal | None
    percent_change: Decimal | None
    changed: bool
    reason: str


@dataclass(slots=True)
class ItemState:
    inventory: InventoryRow
    match: MatchResult = field(default_factory=lambda: MatchResult(status=MatchStatus.UNMATCHED, method="none", approved=False))
    price: PriceResult | None = None
    decision: PricingDecision | None = None
    do_not_update: bool = False
    manual_price_override: Decimal | None = None
    error: str | None = None


@dataclass(slots=True)
class RunSummary:
    total_rows: int = 0
    valid_rows: int = 0
    matched_rows: int = 0
    ambiguous_rows: int = 0
    failed_rows: int = 0
    changed_rows: int = 0
    skipped_rows: int = 0


@dataclass(slots=True)
class RunResult:
    started_at: datetime
    ended_at: datetime
    summary: RunSummary
    output_files: dict[str, str]
    errors: list[str]
