# Full scientific inputs

Place campaign-scale FASTA/PDB/JSON here (or document download URLs).

Demo fixtures under `fixtures/demo/` are intentionally tiny for CI and
walkthroughs. Full runs should use laboratory-scale libraries:

- `sequences.fasta` — parent + large mutant / peptide libraries
- Target PDBs for antibody and inverse-fold campaigns
- JSON inputs matching each protocol's `inputs` schema

Framework repos pin these protocol paths and supply their own `data/full/`
when needed.
