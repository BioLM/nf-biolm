#!/usr/bin/env python3
"""Filter/rank records from a protocol_run/mock_protocol envelope.

Generic helper used by library_screen (filter on pLDDT/Tm) and
trickle_screen (pick survivors for the next round).
"""
import argparse
import json


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input", required=True, help="Path to a protocol result envelope JSON file")
    ap.add_argument("--output", required=True, help="Path to write the filtered envelope JSON")
    ap.add_argument("--sort-by", required=True, help="Numeric field to sort on")
    ap.add_argument("--descending", action="store_true", default=True)
    ap.add_argument("--ascending", dest="descending", action="store_false")
    ap.add_argument("--top", type=int, default=None, help="Keep only the top N records")
    ap.add_argument("--filter-field", default=None, help="Numeric field to threshold on (default: --sort-by)")
    ap.add_argument("--min-value", type=float, default=None, help="Drop records below --filter-field's value")
    args = ap.parse_args()
    filter_field = args.filter_field or args.sort_by

    with open(args.input) as fh:
        envelope = json.load(fh)

    records = envelope.get("records") or []

    def sort_key(rec):
        value = rec.get(args.sort_by)
        return value if isinstance(value, (int, float)) else float("-inf")

    if args.min_value is not None:
        records = [r for r in records if isinstance(r.get(filter_field), (int, float)) and r[filter_field] >= args.min_value]

    records = sorted(records, key=sort_key, reverse=args.descending)
    if args.top is not None:
        records = records[: args.top]

    envelope = dict(envelope)
    envelope["records"] = records
    envelope["filtered_by"] = {
        "sort_by": args.sort_by,
        "descending": args.descending,
        "top": args.top,
        "filter_field": filter_field,
        "min_value": args.min_value,
    }

    with open(args.output, "w") as fh:
        json.dump(envelope, fh, indent=2, default=str)

    print(f"[pick_top_records] kept {len(records)} record(s) sorted by '{args.sort_by}' -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
