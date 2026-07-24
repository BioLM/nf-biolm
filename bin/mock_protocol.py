#!/usr/bin/env python3
"""Cheap local mock for a biolm-protocols/*.yaml run — used only when --demo
is set.

Fabricates deterministic, plausibly-shaped records (no token, no network) so
protocol-based workflows can be smoke-tested end to end. Shapes mirror each
protocol's `response_mapping` keys (see biolm-protocols/protocols/<id>/protocol.yaml)
so downstream summarizers behave the same whether fed mock or real records.

Writes the same normalized envelope as bin/protocol_run.py:
    {"workflow_id": ..., "mode": "mock", "records": [...]}
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _biolm_demo_utils import fake_pdb, fake_score, fake_vector, mutate_sequence, read_json, warn, write_json  # noqa: E402

DEFAULT_HEAVY = "QVQLVQSGAEVKKPGASVKVSCKASGYTFTNYWMNWVKQAPGQGLEWIGYINPYNDGTKYNEKFKGKATLTADKSSSTAYMQLSSLTSEDSAVYYCARYYDDHYCLDYWGQGTTLTVSS"
DEFAULT_LIGHT = "DIQMTQSPSSLSASVGDRVTITCSASSSVSYMHWYQQKPGKAPKPLIYAPSNLASGVPSRFSGSGSGTDFTLTISSLQPEDFATYYCQQWSSNPPTFGQGTKVEIK"
DEFAULT_DESIGN_SEED = "MKTAYIAKQRQISFVKSHFSRQLEERLGLIEVQ"



# NOTE on field naming: a live `biolm protocol run-local` smoke test of
# library_screen showed that a `sequences` (plural) *list* input explodes to
# one row per item with a *singular* `sequence` column, while declared
# `response_mapping` target columns (e.g. `tm`, `mean_plddt`) come through
# as named. These mocks follow that same convention so downstream tooling
# (bin/summarize_records.py, bin/pick_top_records.py, ...) sees the same
# column names whether fed mock or real records.


def mock_embed_cluster(inputs: dict) -> list:
    seqs = inputs.get("sequences", [])
    return [
        {"sequence": s, "embedding": fake_vector(s, dim=8), "tm": fake_score(s, 40.0, 90.0, ndigits=2)}
        for s in seqs
    ]


def mock_dms_landscape(inputs: dict) -> list:
    seqs = inputs.get("sequences", [])
    wildtype = inputs.get("wildtype", "")
    records = []
    for s in seqs:
        delta = fake_score(f"{wildtype}|{s}", -4.0, 4.0, ndigits=3)
        records.append({"sequence": s, "score": delta})
    return records


def mock_library_screen(inputs: dict) -> list:
    seqs = inputs.get("sequences", [])
    return [
        {
            "sequence": s,
            "pdb": fake_pdb(s),
            "mean_plddt": fake_score(s, 55.0, 96.0, ndigits=2),
            "tm": fake_score(s + "|tm", 40.0, 90.0, ndigits=2),
        }
        for s in seqs
    ]


def mock_sat_mut_stability(inputs: dict) -> list:
    seqs = inputs.get("sequences", [])
    return [{"sequence": s, "stability": fake_score(s, -3.0, 3.0, ndigits=3)} for s in seqs]


def mock_biosecurity_screen(inputs: dict) -> list:
    seqs = inputs.get("sequences", [])
    records = []
    for s in seqs:
        risk = fake_score(s + "|risk", 0.0, 1.0, ndigits=3)
        records.append({
            "sequence": s,
            # Mirror live biolmtox2 + protocol mapping (toxin_score <- score).
            "toxin_score": risk,
            "label": "toxin" if risk > 0.5 else "not-toxin",
            "embedding": fake_vector(s, dim=8),
        })
    return records


def mock_antibody_campaign(inputs: dict) -> list:
    n = int(inputs.get("num_seq_per_target", 4) or 4)
    records = []
    for i in range(n):
        heavy = mutate_sequence(DEFAULT_HEAVY, i)
        light = mutate_sequence(DEFAULT_LIGHT, i)
        records.append({
            "heavy": heavy,
            "light": light,
            "score": fake_score(f"{heavy}|{light}|score", 0.55, 0.97, ndigits=3),
            "global_score": fake_score(f"{heavy}|{light}|global", 0.5, 0.9, ndigits=3),
            "mutations": int(fake_score(f"{heavy}|{light}|mut", 3, 18, ndigits=0)),
            "embedding": fake_vector(heavy + light, dim=8),
        })
    return records


def mock_inverse_fold(inputs: dict) -> list:
    n = int(inputs.get("batch_size", 8) or 8)
    return [{"sequence": mutate_sequence(DEFAULT_DESIGN_SEED, i)} for i in range(n)]


SHAPES = {
    "embed_cluster": mock_embed_cluster,
    "dms_landscape": mock_dms_landscape,
    "library_screen": mock_library_screen,
    "sat_mut_stability": mock_sat_mut_stability,
    "biosecurity_screen": mock_biosecurity_screen,
    "antibody_campaign": mock_antibody_campaign,
    "inverse_fold": mock_inverse_fold,
}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--label", required=True, help="Display/tag label, e.g. library_screen_r2")
    ap.add_argument("--shape", required=False, default=None, choices=sorted(SHAPES),
                     help="Catalog shape key controlling mock output shape (default: --label)")
    ap.add_argument("--inputs", required=True, help="Path to a JSON inputs file")
    ap.add_argument("--output", required=True, help="Path to write the normalized JSON result")
    args = ap.parse_args()
    shape = args.shape or args.label
    if shape not in SHAPES:
        sys.exit(f"ERROR: no mock shape for '{shape}'; pass --shape explicitly (one of {sorted(SHAPES)})")

    inputs = read_json(args.inputs)
    warn(f"label={args.label} shape={shape} inputs_keys={list(inputs)} (mock, no live API call)")

    records = SHAPES[shape](inputs)
    envelope = {"workflow_id": args.label, "mode": "mock", "records": records}
    write_json(args.output, envelope)
    warn(f"wrote {len(records)} record(s) to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
