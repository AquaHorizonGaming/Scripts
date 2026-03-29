from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import time
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from .models import MatchCandidate, PriceResult
from .utils import d


@dataclass(slots=True)
class TCGplayerProvider:
    public_key: str
    private_key: str
    access_token: str
    timeout: float = 20
    retry_count: int = 3
    retry_backoff: float = 1.5
    sleep_between_requests: float = 0.1

    base_url: str = "https://api.tcgplayer.com"

    def __post_init__(self) -> None:
        self.session = requests.Session()
        retries = Retry(total=self.retry_count, backoff_factor=self.retry_backoff, status_forcelist=[429, 500, 502, 503, 504])
        self.session.mount("https://", HTTPAdapter(max_retries=retries))

    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"bearer {self.access_token}"}

    def _get(self, path: str, params: dict | None = None) -> dict:
        time.sleep(self.sleep_between_requests)
        resp = self.session.get(f"{self.base_url}{path}", headers=self._headers(), params=params, timeout=self.timeout)
        resp.raise_for_status()
        return resp.json()

    def get_product(self, product_id: int) -> dict | None:
        data = self._get(f"/catalog/products/{product_id}")
        results = data.get("results") or []
        return results[0] if results else None

    def get_sku(self, sku_id: int) -> dict | None:
        data = self._get(f"/catalog/skus/{sku_id}")
        results = data.get("results") or []
        return results[0] if results else None

    def search_products(self, card_name: str, set_name: str | None = None, limit: int = 20) -> list[MatchCandidate]:
        params = {"productName": card_name, "limit": limit}
        data = self._get("/catalog/products", params=params)
        out: list[MatchCandidate] = []
        for item in data.get("results") or []:
            conf = 0.6
            name = item.get("name", "")
            group = item.get("groupName")
            if name.lower() == card_name.lower():
                conf += 0.3
            if set_name and group and group.lower() == set_name.lower():
                conf += 0.1
            out.append(
                MatchCandidate(
                    product_id=int(item["productId"]),
                    sku_id=None,
                    product_name=name,
                    set_name=group,
                    finish=None,
                    condition=None,
                    language=None,
                    confidence=min(conf, 0.99),
                    notes="search",
                )
            )
        return out

    def get_pricing(self, product_id: int | None = None, sku_id: int | None = None) -> PriceResult | None:
        if sku_id:
            data = self._get(f"/pricing/sku/{sku_id}")
            results = data.get("results") or []
            row = results[0] if results else {}
        elif product_id:
            data = self._get(f"/pricing/product/{product_id}")
            results = data.get("results") or []
            row = results[0] if results else {}
        else:
            return None
        if not row:
            return None
        return PriceResult(
            market_price=d(row.get("marketPrice")),
            low_price=d(row.get("lowPrice")),
            mid_price=d(row.get("midPrice")),
            high_price=d(row.get("highPrice")),
            finish=row.get("subTypeName") or row.get("finish"),
            source="tcgplayer",
            lookup_timestamp=datetime.now(timezone.utc),
            lookup_status="ok",
        )
