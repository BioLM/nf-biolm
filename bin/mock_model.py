#!/usr/bin/env python3
"""Cheap local mock for `biolm model run` — used only when --demo is set.

Fabricates a plausibly-shaped result (no token, no network) so structure
prediction workflows can be smoke-tested. Currently understands the
structure-prediction shape (esmfold / boltz-2 predict); other actions fall
back to a generic mocked payload.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _biolm_demo_utils import fake_pdb, fake_score, fake_vector, warn, write_json  # noqa: E402


def read_fasta_sequence(path: str) -> str:
    seq = []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith(">"):
                continue
            seq.append(line)
    return "".join(seq)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--model", required=True)
    ap.add_argument("--action", required=True)
    ap.add_argument("--input", required=True, help="FASTA input file")
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    sequence = read_fasta_sequence(args.input)
    warn(f"model={args.model} action={args.action} seq_len={len(sequence)} (mock, no live API call)")

    if args.action == "predict":
        result = {
            "pdb": fake_pdb(sequence or args.input),
            "mean_plddt": fake_score(sequence or args.input, 55.0, 96.0, ndigits=2),
            "sequence": sequence,
            "model": args.model,
            "mock": True,
        }
    elif args.action == "encode":
        result = {
            "mean_representation": fake_vector(sequence or args.input, dim=8),
            "sequence": sequence,
            "model": args.model,
            "mock": True,
        }
    else:
        result = {"sequence": sequence, "model": args.model, "action": args.action, "mock": True}

    write_json(args.output, result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
