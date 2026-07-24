#!/usr/bin/env python3
"""Combine trickle_screen's per-round library_screen result envelopes into a
single progression CSV (round, sequence, mean_plddt, tm)."""
import argparse
import csv
import json
import re

ROUND_RE = re.compile(r"library_screen_r(\d+)")


def round_from_workflow_id(workflow_id: str, fallback: int) -> int:
    match = ROUND_RE.search(workflow_id or "")
    return int(match.group(1)) if match else fallback


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("result_jsons", nargs="+")
    ap.add_argument("--output-csv", required=True)
    args = ap.parse_args()

    rows = []
    for i, path in enumerate(args.result_jsons, start=1):
        with open(path) as fh:
            envelope = json.load(fh)
        round_num = round_from_workflow_id(envelope.get("workflow_id", ""), i)
        for rec in envelope.get("records") or []:
            seq = rec.get("sequence") or rec.get("sequences")
            rows.append({
                "round": round_num,
                "sequence": seq,
                "mean_plddt": rec.get("mean_plddt"),
                "tm": rec.get("tm"),
            })

    rows.sort(key=lambda r: (r["round"], -(r["tm"] if isinstance(r["tm"], (int, float)) else float("-inf"))))

    with open(args.output_csv, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=["round", "sequence", "mean_plddt", "tm"])
        writer.writeheader()
        writer.writerows(rows)

    n_rounds = len({r["round"] for r in rows})
    print(f"[combine_trickle_rounds] {len(rows)} record(s) across {n_rounds} round(s) -> {args.output_csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
