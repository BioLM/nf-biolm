#!/usr/bin/env python3
"""Advance one round of trickle_screen: pick survivors from the previous
round's library_screen result and append freshly mutated candidates for the
next round's `sequences` input.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _biolm_demo_utils import first_present, mutate_sequence, read_json, warn, write_json  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--previous-result", required=True, help="Path to previous round's *.result.json envelope")
    ap.add_argument("--round", type=int, required=True, help="Round number just completed (1-indexed)")
    ap.add_argument("--survivors", type=int, default=2, help="How many top-tm sequences to keep")
    ap.add_argument("--new-per-round", type=int, default=2, help="How many freshly mutated sequences to add")
    ap.add_argument("--output", required=True, help="Path to write next round's inputs.json")
    args = ap.parse_args()

    envelope = read_json(args.previous_result)
    records = envelope.get("records") or []

    scored = [r for r in records if isinstance(first_present(r), str) and isinstance(r.get("tm"), (int, float))]
    scored.sort(key=lambda r: r["tm"], reverse=True)
    survivors = [first_present(r) for r in scored[: args.survivors]] or [first_present(r) for r in records[: args.survivors]]
    survivors = [s for s in survivors if s]

    if not survivors:
        warn(f"round {args.round}: no usable survivors found in {args.previous_result}; cannot advance")
        write_json(args.output, {"sequences": []})
        return 0

    new_variants = []
    for i in range(args.new_per_round):
        parent = survivors[i % len(survivors)]
        new_variants.append(mutate_sequence(parent, variant_index=args.round * 100 + i))

    next_pool = survivors + new_variants
    warn(f"round {args.round} -> {args.round + 1}: kept {len(survivors)} survivor(s), added {len(new_variants)} new variant(s)")
    write_json(args.output, {"sequences": next_pool})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
