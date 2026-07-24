#!/usr/bin/env python3
"""Summarize a batch of MODEL_RUN esmfold/boltz-2 JSON results (one file per
sequence, as produced by workflows/parallel_fold_farm.nf) into one CSV."""
import argparse
import csv
import json
import statistics


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("json_files", nargs="+")
    ap.add_argument("--output-csv", required=True)
    args = ap.parse_args()

    rows = []
    for path in args.json_files:
        with open(path) as fh:
            data = json.load(fh)
        if isinstance(data, list):
            data = data[0] if data else {}
        rows.append({
            "file": path,
            "sequence_length": len(data.get("sequence") or ""),
            "mean_plddt": data.get("mean_plddt"),
            "model": data.get("model"),
        })

    with open(args.output_csv, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=["file", "sequence_length", "mean_plddt", "model"])
        writer.writeheader()
        writer.writerows(rows)

    plddts = [r["mean_plddt"] for r in rows if isinstance(r["mean_plddt"], (int, float))]
    summary = f"mean={statistics.fmean(plddts):.2f}" if plddts else "n/a"
    print(f"[fold_farm_summary] {len(rows)} structure(s), mean_plddt {summary} -> {args.output_csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
