#!/usr/bin/env python3
"""Turn a protocol_run/mock_protocol envelope into a flat CSV + short summary.

Generic across workflows: flattens scalar fields (numbers/strings) into CSV
columns, drops/collapses nested values (dicts, lists, e.g. embeddings) to a
short placeholder so the CSV stays readable, and prints a one-line summary
per numeric field (min/mean/max) to stdout.
"""
import argparse
import csv
import json
import statistics
import sys


def flatten_record(record: dict) -> dict:
    flat = {}
    for key, value in record.items():
        if isinstance(value, (list, tuple)):
            if value and all(isinstance(v, (int, float)) for v in value):
                flat[key] = f"<vector[{len(value)}]>"
            else:
                flat[key] = f"<list[{len(value)}]>"
        elif isinstance(value, dict):
            for sub_key, sub_value in value.items():
                flat[f"{key}.{sub_key}"] = sub_value
        else:
            flat[key] = value
    return flat


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input", required=True, help="Path to a protocol result envelope JSON file")
    ap.add_argument("--output-csv", required=True)
    args = ap.parse_args()

    with open(args.input) as fh:
        envelope = json.load(fh)

    records = envelope.get("records") or []
    workflow_id = envelope.get("workflow_id", "?")
    mode = envelope.get("mode", "?")

    flat_records = [flatten_record(r) for r in records if isinstance(r, dict)]

    fieldnames = []
    for rec in flat_records:
        for key in rec:
            if key not in fieldnames:
                fieldnames.append(key)

    with open(args.output_csv, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        for rec in flat_records:
            writer.writerow(rec)

    print(f"[summarize] {workflow_id} ({mode} mode): {len(records)} record(s) -> {args.output_csv}")
    for key in fieldnames:
        values = [r[key] for r in flat_records if isinstance(r.get(key), (int, float))]
        if values:
            print(
                f"  {key}: min={min(values):.4g} mean={statistics.fmean(values):.4g} max={max(values):.4g}"
            )

    if not records:
        print(f"  (no records — see .command.err in results/{workflow_id}/ for details)", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
