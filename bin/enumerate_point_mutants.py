#!/usr/bin/env python3
"""Enumerate a saturation-mutagenesis-style single-point-mutant library from
a wild-type sequence, for feeding into sat_mut_stability (or any
`sequences`-shaped protocol input).

Kept deliberately small: caps total variants for demo/CI friendliness.
"""
import argparse
import json

AMINO_ACIDS = "ACDEFGHIKLMNPQRSTVWY"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--wildtype", required=True)
    ap.add_argument("--positions", default=None, help="Comma-separated 1-indexed positions (default: all)")
    ap.add_argument("--max-variants", type=int, default=40, help="Cap the enumerated library size")
    ap.add_argument("--include-wildtype", action="store_true", default=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    wt = args.wildtype.strip().upper()
    if args.positions:
        positions = [int(p) - 1 for p in args.positions.split(",")]
    else:
        positions = list(range(len(wt)))

    variants = [wt] if args.include_wildtype else []
    for pos in positions:
        if pos < 0 or pos >= len(wt):
            continue
        for aa in AMINO_ACIDS:
            if aa == wt[pos]:
                continue
            variants.append(wt[:pos] + aa + wt[pos + 1:])
            if len(variants) >= args.max_variants:
                break
        if len(variants) >= args.max_variants:
            break

    with open(args.output, "w") as fh:
        json.dump({"sequences": variants}, fh, indent=2)

    print(f"[enumerate_point_mutants] wrote {len(variants)} variant(s) (wildtype len={len(wt)}) -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
