#!/usr/bin/env python3
"""Run a shared biolm-protocols/*.yaml protocol via the `biolm` CLI.

Two modes:
  local  -> `biolm protocol run-local <protocol.yaml> --input k=v ...`
            Model calls happen in-process, so this honors the hub switch
            (BIOLM_BASE_API_URL). Preferred default.
  hosted -> `biolm protocol run <slug> --inputs <file> --wait`
            Orchestration stays on the BioLM platform; <slug> must already
            be registered there (see biolm-protocols catalog.json `name`).

Shells out to `biolm` (list-based subprocess, no shell quoting problems even
for inputs containing PDB text with embedded newlines) instead of
`import biolm`, so this script itself never needs biolm-sdk installed under
whatever python3 happens to be first on PATH.

Writes a small normalized envelope to --output:
    {"workflow_id": ..., "mode": "local"|"hosted", "records": [...], "raw": ...}
so downstream summarizers can treat local/hosted/mock results identically.
"""
import argparse
import json
import shutil
import subprocess
import sys


def run_local(protocol_yaml: str, inputs: dict, output_dir: str) -> dict:
    cmd = ["biolm", "protocol", "run-local", protocol_yaml]
    for key, value in inputs.items():
        cmd += ["--input", f"{key}={json.dumps(value)}"]
    cmd += ["--json", "--output-dir", output_dir]

    print(f"[protocol_run] biolm protocol run-local {protocol_yaml} (+{len(inputs)} inputs)", file=sys.stderr)
    result = subprocess.run(cmd, capture_output=True, text=True)
    sys.stderr.write(result.stderr)
    if result.returncode != 0:
        sys.stdout.write(result.stdout)
        sys.exit(f"ERROR: `biolm protocol run-local` failed (exit {result.returncode})")

    stdout = result.stdout.strip()
    try:
        records = json.loads(stdout) if stdout else []
    except json.JSONDecodeError:
        print("[protocol_run] could not parse run-local --json output; wrapping raw stdout", file=sys.stderr)
        records = []
        return {"records": records, "raw": stdout}
    if not isinstance(records, list):
        records = [records]
    return {"records": records, "raw": records}


def run_hosted(slug: str, inputs_path: str) -> dict:
    cmd = ["biolm", "protocol", "run", slug, "--inputs", inputs_path, "--wait", "--format", "json"]

    print(f"[protocol_run] biolm protocol run {slug} --wait", file=sys.stderr)
    result = subprocess.run(cmd, capture_output=True, text=True)
    sys.stderr.write(result.stderr)
    if result.returncode != 0:
        sys.stdout.write(result.stdout)
        sys.exit(f"ERROR: `biolm protocol run` failed (exit {result.returncode})")

    stdout = result.stdout.strip()
    try:
        payload = json.loads(stdout) if stdout else {}
    except json.JSONDecodeError:
        return {"records": [], "raw": stdout}

    records = []
    if isinstance(payload, dict):
        for key in ("records", "results"):
            value = payload.get(key)
            if isinstance(value, list):
                records = value
                break
    elif isinstance(payload, list):
        records = payload

    return {"records": records, "raw": payload}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--mode", choices=["local", "hosted"], required=True)
    ap.add_argument("--workflow-id", required=True)
    ap.add_argument("--protocol-yaml", help="Path to protocol.yaml (local mode)")
    ap.add_argument("--slug", help="Registered protocol name/slug (hosted mode)")
    ap.add_argument("--inputs", required=True, help="Path to a JSON inputs file")
    ap.add_argument("--output", required=True, help="Path to write the normalized JSON result")
    ap.add_argument("--output-dir", default=".", help="Pipeline artifact dir (local mode)")
    args = ap.parse_args()

    if shutil.which("biolm") is None:
        sys.exit(
            "ERROR: `biolm` CLI not found on PATH.\n"
            "Install with: pip install 'biolm-sdk[pipeline]'"
        )

    with open(args.inputs) as fh:
        inputs = json.load(fh)

    if args.mode == "local":
        if not args.protocol_yaml:
            sys.exit("ERROR: --protocol-yaml is required for --mode local")
        payload = run_local(args.protocol_yaml, inputs, args.output_dir)
    else:
        if not args.slug:
            sys.exit("ERROR: --slug is required for --mode hosted")
        payload = run_hosted(args.slug, args.inputs)

    envelope = {"workflow_id": args.workflow_id, "mode": args.mode, **payload}
    with open(args.output, "w") as fh:
        json.dump(envelope, fh, indent=2, default=str)

    print(f"[protocol_run] wrote {len(envelope.get('records') or [])} record(s) to {args.output}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
