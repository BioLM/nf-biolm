#!/usr/bin/env python3
"""Thin wrapper around `biolm model run`.

Shells out to the `biolm` CLI rather than `import biolm` directly, so this
script works with whatever python3 happens to be first on PATH inside a
Nextflow task — the `biolm` executable carries its own interpreter shebang
from wherever `pip install biolm-sdk` put it.
"""
import argparse
import shutil
import subprocess
import sys


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("model", help="Model slug, e.g. esmfold, esm2-150m")
    ap.add_argument("action", choices=["encode", "predict", "generate", "lookup"])
    ap.add_argument("--input", "-i", required=True, help="Input file path")
    ap.add_argument("--output", "-o", required=True, help="Output file path")
    ap.add_argument("--input-format", default=None, choices=["json", "fasta", "csv", "pdb"])
    ap.add_argument("--format", default=None, choices=["json", "fasta", "csv", "pdb"])
    ap.add_argument("--params", default=None, help="JSON string or file path")
    args = ap.parse_args()

    if shutil.which("biolm") is None:
        sys.exit(
            "ERROR: `biolm` CLI not found on PATH.\n"
            "Install with: pip install 'biolm-sdk[pipeline]'"
        )

    cmd = [
        "biolm", "model", "run", args.model, args.action,
        "-i", args.input, "-o", args.output,
    ]
    if args.input_format:
        cmd += ["--input-format", args.input_format]
    if args.format:
        cmd += ["--format", args.format]
    if args.params:
        cmd += ["--params", args.params]

    print(f"[model_run] {' '.join(cmd)}", file=sys.stderr)
    result = subprocess.run(cmd, capture_output=True, text=True)
    sys.stderr.write(result.stderr)
    sys.stdout.write(result.stdout)
    if result.returncode != 0:
        sys.exit(f"ERROR: `biolm model run` failed (exit {result.returncode})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
