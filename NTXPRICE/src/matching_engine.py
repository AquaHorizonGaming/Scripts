from __future__ import annotations

from .models import ItemState, MatchResult, MatchStatus
from .validators import parse_id_from_url


class MatchingEngine:
    def __init__(self, provider, logger, include_out_of_stock: bool = False) -> None:
        self.provider = provider
        self.logger = logger
        self.include_out_of_stock = include_out_of_stock

    def match_item(self, item: ItemState) -> MatchResult:
        inv = item.inventory
        if (not inv.in_stock) and (not self.include_out_of_stock):
            return MatchResult(status=MatchStatus.UNMATCHED, method="skipped_out_of_stock", approved=False, notes="Out of stock")

        try:
            if inv.tcgplayer_sku_id:
                sku = self.provider.get_sku(inv.tcgplayer_sku_id)
                if sku:
                    return MatchResult(
                        status=MatchStatus.MATCHED,
                        method="sku_id",
                        product_id=sku.get("productId"),
                        sku_id=inv.tcgplayer_sku_id,
                        product_name=sku.get("productName"),
                        finish=sku.get("printing"),
                        condition=sku.get("condition"),
                        language=sku.get("language"),
                        confidence=1.0,
                        notes="Matched by tcgplayer_sku_id",
                    )

            if inv.tcgplayer_product_id:
                p = self.provider.get_product(inv.tcgplayer_product_id)
                if p:
                    return MatchResult(
                        status=MatchStatus.MATCHED,
                        method="product_id",
                        product_id=inv.tcgplayer_product_id,
                        product_name=p.get("name"),
                        set_name=p.get("groupName"),
                        confidence=0.95,
                        notes="Matched by tcgplayer_product_id",
                    )

            if inv.tcgplayer_url:
                product_id, sku_id = parse_id_from_url(inv.tcgplayer_url)
                if sku_id:
                    sku = self.provider.get_sku(sku_id)
                    if sku:
                        return MatchResult(status=MatchStatus.MATCHED, method="url_sku", product_id=sku.get("productId"), sku_id=sku_id, product_name=sku.get("productName"), confidence=0.92)
                if product_id:
                    p = self.provider.get_product(product_id)
                    if p:
                        return MatchResult(status=MatchStatus.MATCHED, method="url_product", product_id=product_id, product_name=p.get("name"), confidence=0.9)

            cands = self.provider.search_products(inv.card_name, inv.set_name)
            if not cands:
                return MatchResult(status=MatchStatus.UNMATCHED, method="search", notes="No candidates", approved=False)
            cands = sorted(cands, key=lambda c: c.confidence, reverse=True)
            if len(cands) > 1 and abs(cands[0].confidence - cands[1].confidence) < 0.08:
                return MatchResult(status=MatchStatus.AMBIGUOUS, method="search", candidates=cands[:5], confidence=cands[0].confidence, approved=False, notes="Manual review required")

            best = cands[0]
            return MatchResult(
                status=MatchStatus.MATCHED,
                method="search",
                product_id=best.product_id,
                sku_id=best.sku_id,
                product_name=best.product_name,
                set_name=best.set_name,
                finish=best.finish,
                condition=best.condition,
                language=best.language,
                confidence=best.confidence,
                candidates=cands[:5],
            )
        except Exception as exc:
            self.logger.exception("Match failure for sku=%s", inv.sku)
            return MatchResult(status=MatchStatus.ERROR, method="error", notes=str(exc), approved=False)

    def run(self, items: list[ItemState]) -> None:
        for item in items:
            item.match = self.match_item(item)
