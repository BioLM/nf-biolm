# Quick Start Guide

Get up and running with BioLM SDK in Nextflow in under 5 minutes!

## Step 1: Install Dependencies

```bash
# Install BioLM SDK
pip install biolmai

# Install Nextflow (if needed)
curl -s https://get.nextflow.io | bash
```

## Step 2: Get Your BioLM Token

1. Visit [BioLM](https://biolm.ai/)
2. Sign up and get your API token
3. Set it as an environment variable:
   ```bash
   export BIOLMAI_TOKEN="your_token_here"
   ```

## Step 3: Run the Workflow

### Option A: Quick Demo (Recommended for first-time users)
```bash
# Run the demo workflow
nextflow run intro.nf --demo
```

This will:
- Run a single protein sequence prediction
- Output results to `results/DEMO.pdb`
- Show you the basic BioLM + Nextflow integration

### Option B: Default Example
```bash
# Run with default GFP sequence
nextflow run intro.nf
```

This will:
- Use the GFP protein sequence
- Output results to `results/GFP.pdb`

### Option C: Your Own Sequences
```bash
# Run with your FASTA file
nextflow run intro.nf --input your_proteins.fasta
```

This will:
- Process all sequences in your FASTA file
- Output one PDB file per sequence

## Step 4: Check Results

```bash
# List output files
ls -la results/

# View PDB structure (first few lines)
head -20 results/*.pdb
```

## What You Get

- **PDB Files**: Standard protein structure files ready for visualization
- **Clean Output**: No intermediate JSON files, just the structures you need
- **Scalable**: Can process single sequences or entire FASTA files

## Next Steps

- **Visualize**: Open PDB files in tools like PyMOL, Chimera, or online viewers
- **Customize**: Modify the workflow for your specific needs
- **Scale Up**: Process larger datasets with more compute resources

## Troubleshooting

- **Token Error**: Make sure `BIOLMAI_TOKEN` is set correctly
- **Import Error**: Run `pip install biolmai`
- **Rate Limits**: Wait a few seconds between runs if you hit API limits
