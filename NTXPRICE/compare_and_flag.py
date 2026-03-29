from __future__ import annotations

import argparse
import csv
from pathlib import Path


def compare_and_flag(input_csv: str, output_csv: str, threshold: float = 0.0, direction: str = "both") -> int:
    rows_out = []
    with open(input_csv, "r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            cur = float(row.get("current_price") or 0)
            new = float(row.get("new_price") or 0)
            delta = new - cur
            if abs(delta) < threshold:
                continue
            if direction == "increases" and delta <= 0:
                continue
            if direction == "decreases" and delta >= 0:
                continue
            row["delta"] = f"{delta:.2f}"
            rows_out.append(row)

    Path(output_csv).parent.mkdir(parents=True, exist_ok=True)
    fields = rows_out[0].keys() if rows_out else ["sku", "current_price", "new_price", "delta"]
    with open(output_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(fields))
        w.writeheader()
        w.writerows(rows_out)
    return len(rows_out)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="data/site_import.csv")
    parser.add_argument("--output", default="data/price_changes_only.csv")
    parser.add_argument("--threshold", type=float, default=0.0)
    parser.add_argument("--direction", choices=["increases", "decreases", "both"], default="both")
    args = parser.parse_args()
    count = compare_and_flag(args.input, args.output, args.threshold, args.direction)
    print(f"Wrote {count} changed rows to {args.output}")
