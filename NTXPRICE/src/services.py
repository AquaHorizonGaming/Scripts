from __future__ import annotations

from dataclasses import dataclass
from .models import RunSummary, ItemState, MatchStatus


@dataclass(slots=True)
class MetricsService:
    @staticmethod
    def summarize(items: list[ItemState]) -> RunSummary:
        s = RunSummary(total_rows=len(items))
        for i in items:
            if not i.inventory.validation_errors:
                s.valid_rows += 1
            if i.match.status == MatchStatus.MATCHED:
                s.matched_rows += 1
            elif i.match.status == MatchStatus.AMBIGUOUS:
                s.ambiguous_rows += 1
            elif i.match.status in {MatchStatus.UNMATCHED, MatchStatus.ERROR}:
                s.failed_rows += 1
            if i.decision and i.decision.changed:
                s.changed_rows += 1
            if i.do_not_update or i.match.status != MatchStatus.MATCHED:
                s.skipped_rows += 1
        return s
