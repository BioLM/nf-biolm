# nf-biolm: BioLM in Nextflow

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A5%2020.0.0-brightgreen.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/docker-%20%20%F0%9F%8C%A2%20%20run%20with%20docker-blue.svg)](https://www.docker.com/)
[![Launch on Seqera Platform](https://img.shields.io/badge/launch%20on-seqera%20platform-blue.svg)](https://cloud.seqera.io/)
[![BioLM SDK](https://img.shields.io/badge/biolm%20sdk-%E2%89%A5%201.5.0-green.svg)](https://github.com/BioLM/biolm-sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Nextflow DSL2 workflows on the **BioLM SDK** (`biolm` CLI / `import biolm`).
Protocol YAML and demo fixtures are vendored in-repo under `protocols/` and
`fixtures/`. Every workflow supports `--demo` (local mocks, no token).

## Workflows

| Workflow | Kind | Backing protocol / model | Entry point |
|---|---|---|---|
| `structure_predict` | Model | `esmfold` (optional `--boltz2` / `--structure_model boltz-2`) | `workflows/structure_predict.nf` |
| `embed_cluster` | Protocol | `protocols/embed_cluster/protocol.yaml` | `workflows/embed_cluster.nf` |
| `dms_landscape` | Protocol | `protocols/dms_landscape/protocol.yaml` | `workflows/dms_landscape.nf` |
| `antibody_campaign` | Protocol | `protocols/antibody_campaign/protocol.yaml` | `workflows/antibody_campaign.nf` |
| `library_screen` | Protocol | `protocols/library_screen/protocol.yaml` | `workflows/library_screen.nf` |
| `parallel_fold_farm` | Model scatter | `esmfold`/`boltz-2`, one task per sequence | `workflows/parallel_fold_farm.nf` |
| `biosecurity_screen` | Protocol | `protocols/biosecurity_screen/protocol.yaml` | `workflows/biosecurity_screen.nf` |
| `inverse_fold` | Protocol | `protocols/inverse_fold/protocol.yaml` | `workflows/inverse_fold.nf` |
| `sat_mut_stability` | Protocol | `protocols/sat_mut_stability/protocol.yaml` | `workflows/sat_mut_stability.nf` |
| `trickle_screen` | Iterative | `library_screen` protocol, re-run per round | `workflows/trickle_screen.nf` |

Root wrappers: `intro.nf` → `structure_predict`; `antibody_engineering.nf` → `antibody_campaign`.

## Quick Start

### 1. Install dependencies

```bash
# Install the BioLM SDK (replaces the legacy `biolmai` package)
pip install "biolm-sdk[pipeline]"

# Install Nextflow (if needed)
curl -s https://get.nextflow.io | bash
```

`[pipeline]` pulls in the extras needed for `biolm protocol run-local`.

### 2. Try it with no token

```bash
nextflow run workflows/structure_predict.nf --demo
nextflow run workflows/library_screen.nf --demo
```

See [Demo smoke-test commands](#demo-smoke-test-commands) for the full set.

### 3. Get your BioLM token for real runs

1. Visit [BioLM](https://biolm.ai/) and sign up for an API token.
2. Export it:

   ```bash
   export BIOLM_TOKEN="your_token_here"
   ```

   (`BIOLMAI_TOKEN` is still read as a fallback for backward compatibility.)

3. Run the same command without `--demo`:

   ```bash
   nextflow run workflows/structure_predict.nf
   ```

Override the in-repo catalog root with `--protocols_root <path>` or
`BIOLM_PROTOCOLS_ROOT` if needed (default `.`).

## Backend & execution switches

nf-biolm decouples **where models run** from **how protocols are
orchestrated**:

| Param | Values | Meaning |
|---|---|---|
| `--backend` | `platform` (default) \| `hub` | `platform` talks to the hosted `biolm.ai` API. `hub` points the SDK at a local/self-hosted `biolm-hub` gateway via `BIOLM_BASE_API_URL` (set from `--hub_url`). |
| `--hub_url` | URL, default `http://127.0.0.1:8000` | Only used when `--backend hub`. |
| `--execution` | `local` (default) \| `hosted` | `local` runs protocols in-process with `biolm protocol run-local` (works with either backend). `hosted` submits to a registered protocol slug with `biolm protocol run <slug>` — orchestration happens on the BioLM platform itself. |
| `--protocols_root` | path, default `.` (in-repo catalog) (or `$BIOLM_PROTOCOLS_ROOT`) | Where to find `catalog.json`, `protocols/*/protocol.yaml`, and `fixtures/demo/*`. |
| `--demo` | `true` \| `false` (default) | Route model/protocol calls to local mock scripts (`bin/mock_model.py`, `bin/mock_protocol.py`) instead of the real API. No token or network required. |

Examples:

```bash
# Hosted BioLM platform, local orchestration (default)
nextflow run workflows/embed_cluster.nf

# Self-hosted hub, local orchestration
nextflow run workflows/embed_cluster.nf --backend hub --hub_url http://127.0.0.1:8000

# Hosted platform, hosted orchestration (protocol must be registered as a slug)
nextflow run workflows/embed_cluster.nf --execution hosted

# No token, no network — local mocks
nextflow run workflows/embed_cluster.nf --demo
```

Backend/execution configuration lives in `modules/backend.nf`
(`biolmEnvExports()`, `resolveProtocolYaml()`, `resolveDemoInputs()`,
`protocolSlug()`) and is shared by every workflow.

## Demo smoke-test commands

Every command below runs fully offline against `data/demo/*` fixtures and local
mock generators — no `BIOLM_TOKEN` required.

```bash
nextflow run workflows/structure_predict.nf --demo
nextflow run workflows/embed_cluster.nf --demo
nextflow run workflows/dms_landscape.nf --demo
nextflow run workflows/antibody_campaign.nf --demo
nextflow run workflows/library_screen.nf --demo
nextflow run workflows/parallel_fold_farm.nf --demo
nextflow run workflows/biosecurity_screen.nf --demo
nextflow run workflows/inverse_fold.nf --demo
nextflow run workflows/sat_mut_stability.nf --demo
nextflow run workflows/trickle_screen.nf --demo --rounds 3

# Backward-compatible root wrappers
nextflow run intro.nf --demo
nextflow run antibody_engineering.nf --demo
```

Drop `--demo` (and export `BIOLM_TOKEN`) to run any of the above against the
real BioLM API. Some workflows also accept `--input <path>` to override the
bundled demo fixture with your own FASTA/JSON.

## Project structure

```
nf-biolm/
├── intro.nf                    # thin wrapper -> workflows/structure_predict.nf
├── antibody_engineering.nf     # thin wrapper -> workflows/antibody_campaign.nf
├── workflows/                  # the 10 catalog workflows
│   ├── structure_predict.nf
│   ├── embed_cluster.nf
│   ├── dms_landscape.nf
│   ├── antibody_campaign.nf
│   ├── library_screen.nf
│   ├── parallel_fold_farm.nf
│   ├── biosecurity_screen.nf
│   ├── inverse_fold.nf
│   ├── sat_mut_stability.nf
│   └── trickle_screen.nf
├── modules/                     # shared DSL2 processes/functions
│   ├── backend.nf              # backend env config + catalog.json lookups
│   ├── fasta.nf                # SPLIT_FASTA
│   ├── model_run.nf            # MODEL_RUN (biolm model run / mock)
│   ├── protocol_run.nf         # PROTOCOL_RUN (biolm protocol run[-local] / mock)
│   └── trickle_advance.nf      # ADVANCE_ROUND (trickle_screen round logic)
├── bin/                         # executable helper scripts (on $PATH in-process)
│   ├── model_run.py / mock_model.py       # structure_predict, parallel_fold_farm
│   ├── protocol_run.py / mock_protocol.py # every protocol-based workflow
│   ├── extract_pdb.py                     # pull PDB text out of model JSON
│   ├── summarize_records.py               # flatten result envelopes to CSV
│   ├── pick_top_records.py                # library_screen / trickle_screen filtering
│   ├── bucket_by_score.py                 # embed_cluster low/mid/high buckets
│   ├── enumerate_point_mutants.py         # sat_mut_stability library generation
│   ├── flag_toxin_hits.py                 # biosecurity_screen hit flagging
│   ├── records_to_fasta.py                # inverse_fold -> FASTA
│   ├── fold_farm_summary.py               # parallel_fold_farm pLDDT summary
│   ├── combine_trickle_rounds.py          # trickle_screen multi-round CSV
│   └── trickle_advance.py / _biolm_demo_utils.py  # shared round/mock helpers
├── data/demo/                   # tiny fixtures copied from biolm-protocols/fixtures/demo/
├── nextflow.config              # params (backend, execution, protocols_root, demo, ...)
├── requirements.txt             # biolm-sdk[pipeline]
├── tower.yml                    # Seqera Platform configuration
├── LICENSE
└── README.md
```

`.` (sibling checkout, not vendored) supplies `catalog.json`,
`protocols/*/protocol.yaml`, and `fixtures/demo/*.inputs.json` for every
protocol-based workflow above.

## Parameters

| Parameter | Description | Default |
|---|---|---|
| `--token` | BioLM API token | `$BIOLM_TOKEN` (falls back to `$BIOLMAI_TOKEN`) |
| `--backend` | `platform` \| `hub` | `platform` |
| `--hub_url` | Hub gateway URL (when `--backend hub`) | `http://127.0.0.1:8000` |
| `--execution` | `local` \| `hosted` | `local` |
| `--protocols_root` | Path to `biolm-protocols` checkout | `$BIOLM_PROTOCOLS_ROOT` or `.` |
| `--demo` | Use local mocks instead of the live API | `false` |
| `--input` | Override the bundled demo FASTA/JSON input | none |
| `--outdir` | Output directory | `results` |
| `--structure_model` | `esmfold` \| `boltz-2` (`structure_predict`, `parallel_fold_farm`) | `esmfold` |
| `--boltz2` | Shorthand for `--structure_model boltz-2` | `false` |
| `--max_forks` | Parallelism cap for `MODEL_RUN` / `parallel_fold_farm` | `4` |
| `--min_plddt` / `--top_n` | `library_screen` filter thresholds | `0` / `10` |
| `--wildtype` / `--max_variants` | `sat_mut_stability` auto-enumeration | none / `40` |
| `--rounds` / `--survivors` / `--new_per_round` | `trickle_screen` iteration controls | `3` / `2` / `2` |
| `--num_variants` / `--sampling_temp` | Legacy `antibody_engineering` params (kept for compatibility) | `100` / `0.8` |

## ☁️ Launch on Seqera Platform

You can run any workflow directly on [Seqera Platform](https://cloud.seqera.io/)
without local setup:

1. **Click the badge**: [![Launch on Seqera Platform](https://img.shields.io/badge/launch%20on-seqera%20platform-blue.svg)](https://cloud.seqera.io/)
2. **Sign in** to your Seqera Platform account.
3. **Configure parameters**: set `BIOLM_TOKEN`, pick a workflow entry point
   under `workflows/`, and choose `--demo` or real input.
4. **Launch** the workflow.

## Troubleshooting

- **`ModuleNotFoundError` / import errors**: run `pip install "biolm-sdk[pipeline]"`.
  The legacy `biolmai` package is no longer used anywhere in this repo.
- **`Cannot find biolm-protocols catalog.json`**: clone
  the in-repo protocol catalog next to this
  repo, or set `--protocols_root` / `BIOLM_PROTOCOLS_ROOT`.
- **`command not found` for a `bin/*.py` script**: make sure you invoke
  `nextflow run ...` from the `nf-biolm` repo root — `nextflow.config` adds the
  repo-root `bin/` to `PATH` for every process, including `workflows/*.nf`
  entry points.
- **API token issues**: ensure `BIOLM_TOKEN` (or `BIOLMAI_TOKEN`) is set. Use
  `--demo` to sanity-check the pipeline logic without a token at all.
- **Protocol run returns empty records / unexpected keys**: confirm vendored
  `protocols/*/protocol.yaml` `response_mapping` keys match the live API.
  `--demo` mode still works without a token.
- **Workflow errors**: check `.nextflow.log` (or `logs/nextflow.log`) for
  details.

## Related resources

- **Blog Post**: [Scaling BioLM Workflows with Nextflow: From Notebooks to Production Pipelines](https://blog.biolm.ai/scaling-biolm-workflows-with-nextflow/)
- **BioLM Documentation**: [https://biolm.ai/](https://biolm.ai/)
- **Nextflow Documentation**: [https://www.nextflow.io/](https://www.nextflow.io/)
- **Seqera Platform**: [https://cloud.seqera.io/](https://cloud.seqera.io/)
