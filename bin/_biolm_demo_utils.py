"""Deterministic fake-data helpers shared by the mock_* scripts.

Not a public API — just keeps the per-workflow mock generators short. Uses
only the stdlib so the `--demo` path never needs `biolm-sdk` installed.
"""
from __future__ import annotations

import hashlib
import json
import sys

AMINO_ACIDS = "ACDEFGHIKLMNPQRSTVWY"


def _seeded_random(seed_text: str) -> "random.Random":
    import random

    digest = hashlib.sha256(seed_text.encode("utf-8")).hexdigest()
    return random.Random(int(digest[:16], 16))


def fake_score(seed_text: str, lo: float, hi: float, ndigits: int = 4) -> float:
    rng = _seeded_random(f"score::{seed_text}")
    return round(rng.uniform(lo, hi), ndigits)


def fake_vector(seed_text: str, dim: int = 8, ndigits: int = 4) -> list:
    rng = _seeded_random(f"vector::{seed_text}")
    return [round(rng.uniform(-1.0, 1.0), ndigits) for _ in range(dim)]


def mutate_sequence(seq: str, variant_index: int) -> str:
    """Deterministically point-mutate `seq` at a position keyed by variant_index."""
    if not seq:
        return seq
    rng = _seeded_random(f"mutate::{seq}::{variant_index}")
    pos = rng.randrange(len(seq))
    new_aa = rng.choice([aa for aa in AMINO_ACIDS if aa != seq[pos]])
    return seq[:pos] + new_aa + seq[pos + 1:]


def fake_pdb(seed_text: str, chain: str = "A") -> str:
    """A minimal, syntactically-valid single-residue PDB block."""
    rng = _seeded_random(f"pdb::{seed_text}")
    x, y, z = (round(rng.uniform(0, 30), 3) for _ in range(3))
    lines = [
        "HEADER    MOCK STRUCTURE (nf-biolm --demo)",
        f"ATOM      1  N   ALA {chain}   1    {x:8.3f}{y:8.3f}{z:8.3f}  1.00 50.00           N",
        f"ATOM      2  CA  ALA {chain}   1    {x + 1.5:8.3f}{y:8.3f}{z:8.3f}  1.00 50.00           C",
        f"ATOM      3  C   ALA {chain}   1    {x + 3.0:8.3f}{y + 1.0:8.3f}{z:8.3f}  1.00 50.00           C",
        f"ATOM      4  O   ALA {chain}   1    {x + 3.0:8.3f}{y + 2.0:8.3f}{z:8.3f}  1.00 50.00           O",
        "TER",
        "END",
    ]
    return "\n".join(lines) + "\n"


def read_json(path: str):
    with open(path) as fh:
        return json.load(fh)


def write_json(path: str, data) -> None:
    with open(path, "w") as fh:
        json.dump(data, fh, indent=2)


def warn(msg: str) -> None:
    print(f"[mock] {msg}", file=sys.stderr)


def first_present(record: dict, keys=("sequence", "sequences", "heavy")):
    """Best-effort lookup of "the sequence value" across naming conventions.

    Real `biolm protocol run-local` output singularizes an exploded list
    input (`sequences` -> per-row `sequence`), but this isn't a guaranteed
    contract across every protocol, so callers that just want something
    sequence-like to display/mutate should go through this helper instead of
    hardcoding one key name.
    """
    for key in keys:
        if key in record and record[key]:
            return record[key]
    return None
