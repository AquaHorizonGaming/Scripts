from __future__ import annotations

from decimal import Decimal
from .models import ItemState, PricingDecision, PricingBasis, MatchStatus, PriceResult
from .utils import quantize_price, d


class PricingEngine:
    def __init__(
        self,
        provider,
        logger,
        cache_store=None,
        pricing_basis: str = "market_price",
        undercut_amount: float = 0.01,
        min_price: float = 0.01,
        max_price: float = 9999.99,
        fallback_to_current_price: bool = True,
        skip_if_no_market_price: bool = False,
        minimum_change_threshold: float = 0.0,
    ) -> None:
        self.provider = provider
        self.logger = logger
        self.cache = cache_store
        self.pricing_basis = PricingBasis(pricing_basis) if pricing_basis in [e.value for e in PricingBasis] else PricingBasis.MARKET
        self.undercut = Decimal(str(undercut_amount))
        self.min_price = Decimal(str(min_price))
        self.max_price = Decimal(str(max_price))
        self.fallback_to_current_price = fallback_to_current_price
        self.skip_if_no_market_price = skip_if_no_market_price
        self.minimum_change_threshold = Decimal(str(minimum_change_threshold))

    def _select_basis(self, p: PriceResult) -> Decimal | None:
        if self.pricing_basis == PricingBasis.MARKET:
            return p.market_price
        if self.pricing_basis == PricingBasis.MID:
            return p.mid_price
        if self.pricing_basis == PricingBasis.LOW:
            return p.low_price
        return p.market_price or p.mid_price or p.low_price

    def _load_price(self, item: ItemState) -> PriceResult | None:
        key = f"{item.match.product_id}:{item.match.sku_id}"
        if self.cache:
            cached = self.cache.get_pricing_cache(key)
            if cached:
                return PriceResult(
                    market_price=d(cached["market_price"]),
                    low_price=d(cached["low_price"]),
                    mid_price=d(cached["mid_price"]),
                    high_price=d(cached["high_price"]),
                    finish=None,
                    source=cached["source"],
                    lookup_timestamp=__import__("datetime").datetime.fromisoformat(cached["lookup_timestamp"]),
                )
        p = self.provider.get_pricing(item.match.product_id, item.match.sku_id)
        if p and self.cache:
            self.cache.set_pricing_cache(
                key,
                {
                    "market_price": str(p.market_price) if p.market_price is not None else "",
                    "low_price": str(p.low_price) if p.low_price is not None else "",
                    "mid_price": str(p.mid_price) if p.mid_price is not None else "",
                    "high_price": str(p.high_price) if p.high_price is not None else "",
                    "source": p.source,
                    "lookup_timestamp": p.lookup_timestamp.isoformat(),
                },
            )
        return p

    def price_item(self, item: ItemState) -> None:
        if item.match.status != MatchStatus.MATCHED or not item.match.approved:
            return
        if item.do_not_update:
            item.decision = PricingDecision(self.pricing_basis, None, None, None, None, False, "do_not_update")
            return

        price = self._load_price(item)
        item.price = price
        if not price:
            item.decision = PricingDecision(self.pricing_basis, None, None, None, None, False, "no_pricing")
            return

        basis = self._select_basis(price)
        if basis is None:
            if self.skip_if_no_market_price:
                item.decision = PricingDecision(self.pricing_basis, None, None, None, None, False, "missing_basis_skip")
                return
            if self.fallback_to_current_price:
                basis = item.inventory.current_price
            else:
                item.decision = PricingDecision(self.pricing_basis, None, None, None, None, False, "missing_basis")
                return

        new_price = max(self.min_price, min(self.max_price, quantize_price(max(Decimal("0"), basis - self.undercut))))
        if item.manual_price_override is not None:
            new_price = item.manual_price_override

        cur = item.inventory.current_price
        abs_change = quantize_price(new_price - cur)
        pct_change = quantize_price((abs_change / cur) * Decimal("100")) if cur > 0 else Decimal("0")
        changed = abs(abs_change) >= self.minimum_change_threshold
        item.decision = PricingDecision(self.pricing_basis, basis, new_price, abs_change, pct_change, changed, "computed")

    def run(self, items: list[ItemState]) -> None:
        for item in items:
            self.price_item(item)
