#!/usr/bin/env python3
"""Lightweight framework-side "clustering": bucket records into low/med/high
terciles by a numeric field. No ML dependency — just a demo-friendly stand-in
for real downstream clustering/diversification tooling.
"""
import argparse
import csv
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _biolm_demo_utils import first_present  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input", required=True, help="Path to a protocol result envelope JSON file")
    ap.add_argument("--by", required=True, help="Numeric field to bucket on")
    ap.add_argument("--output-csv", required=True)
    args = ap.parse_args()

    with open(args.input) as fh:
        envelope = json.load(fh)
    records = envelope.get("records") or []

    scored = [r for r in records if isinstance(r.get(args.by), (int, float))]
    scored.sort(key=lambda r: r[args.by])
    n = len(scored)

    def bucket_for(i: int) -> str:
        if n <= 1:
            return "mid"
        third = n / 3.0
        if i < third:
            return "low"
        if i < 2 * third:
            return "mid"
        return "high"

    rows = []
    for i, rec in enumerate(scored):
        rows.append({"sequence": first_present(rec), args.by: rec[args.by], "bucket": bucket_for(i)})

    with open(args.output_csv, "w", newline="") as fh:
        fieldnames = ["sequence", args.by, "bucket"]
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    counts = {"low": 0, "mid": 0, "high": 0}
    for row in rows:
        counts[row["bucket"]] += 1
    print(f"[bucket_by_score] bucketed {n} record(s) by '{args.by}': {counts} -> {args.output_csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
