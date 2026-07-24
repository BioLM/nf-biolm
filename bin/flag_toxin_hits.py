#!/usr/bin/env python3
"""Pull out biosecurity_screen records flagged as toxin-like.

Looks for a BioLMTox `label` field and, defensively, numeric
`toxin_score` / `risk_score` / `prediction` / `score` fields.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _biolm_demo_utils import first_present  # noqa: E402

POSITIVE_LABELS = {"toxin-like", "toxin", "positive", "true", "1"}


def is_flagged(record: dict) -> bool:
    label = record.get("label")
    if label is not None:
        return str(label).strip().lower() in POSITIVE_LABELS
    for key in ("toxin_score", "risk_score", "prediction", "score"):
        value = record.get(key)
        if isinstance(value, (int, float)):
            return value >= 0.5
    return False


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    with open(args.input) as fh:
        envelope = json.load(fh)
    records = envelope.get("records") or []

    flagged = [
        {"sequence": first_present(r), **{k: v for k, v in r.items() if k not in ("embedding",)}}
        for r in records
        if is_flagged(r)
    ]

    with open(args.output, "w") as fh:
        json.dump({"workflow_id": "biosecurity_screen", "flagged": flagged}, fh, indent=2, default=str)

    print(f"[flag_toxin_hits] {len(flagged)}/{len(records)} sequence(s) flagged -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
