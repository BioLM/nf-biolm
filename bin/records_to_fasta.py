#!/usr/bin/env python3
"""Write a FASTA file from the sequence-like field of each record in a
protocol_run/mock_protocol envelope (e.g. inverse_fold designs)."""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _biolm_demo_utils import first_present  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--prefix", default="seq")
    args = ap.parse_args()

    with open(args.input) as fh:
        envelope = json.load(fh)
    records = envelope.get("records") or []

    with open(args.output, "w") as fh:
        n = 0
        for i, rec in enumerate(records):
            seq = first_present(rec)
            if not isinstance(seq, str) or not seq:
                continue
            fh.write(f">{args.prefix}_{i}\n{seq}\n")
            n += 1

    print(f"[records_to_fasta] wrote {n} sequence(s) -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
