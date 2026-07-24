#!/usr/bin/env python3
"""Extract a 'pdb' field from a BioLM model-run JSON result.

Handles both a single result dict and a list of result dicts (batched calls),
in which case the first item's `pdb` field is used. Exits 0 with no output
file if no `pdb` field is present, so callers can mark the output optional.
"""
import argparse
import json
import sys


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    with open(args.input) as fh:
        data = json.load(fh)

    if isinstance(data, list):
        data = data[0] if data else {}

    pdb = None
    if isinstance(data, dict):
        pdb = data.get("pdb")

    if not pdb:
        print(f"[extract_pdb] no 'pdb' field in {args.input}; skipping", file=sys.stderr)
        return 0

    with open(args.output, "w") as fh:
        fh.write(pdb)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
