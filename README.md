# nf-biolm: BioLM SDK in Nextflow

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A5%2020.0.0-brightgreen.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/docker-%20%20%F0%9F%8C%A2%20%20run%20with%20docker-blue.svg)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/singularity-%20%20%F0%9F%8C%A2%20%20run%20with%20singularity-orange.svg)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/launch%20on-seqera%20platform-blue.svg)](https://cloud.seqera.io/)
[![BioLM SDK](https://img.shields.io/badge/biolm%20sdk-%E2%89%A5%200.1.0-green.svg)](https://github.com/BioLM/biolm-python)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive example demonstrating how to use the BioLM SDK within Nextflow pipelines for protein structure prediction. This project provides a unified workflow that can run in demo mode or process FASTA files.

## 🚀 Quick Start (5 minutes)

### 1. Install Dependencies
```bash
# Install BioLM SDK
pip install biolmai

# Install Nextflow (if needed)
curl -s https://get.nextflow.io | bash
```

### 2. Get Your BioLM Token
1. Visit [BioLM](https://biolm.ai/)
2. Sign up and get your API token
3. Set it as an environment variable:
   ```bash
   export BIOLMAI_TOKEN="your_token_here"
   ```

### 3. Run the Workflow

**Option A: Quick Demo (Recommended for first-time users)**
```bash
nextflow run intro.nf --demo
# Output: results/DEMO.pdb
```

**Option B: Default Example**
```bash
nextflow run intro.nf
# Output: results/GFP.pdb
```

**Option C: Your Own Sequences**
```bash
nextflow run intro.nf --input your_proteins.fasta
# Output: results/sequence1.pdb, results/sequence2.pdb, etc.
```

### 4. Check Results
```bash
# List output files
ls -la results/

# View PDB structure (first few lines)
head -20 results/*.pdb
```

## ☁️ Launch on Seqera Platform

You can run this workflow directly on [Seqera Platform](https://cloud.seqera.io/) without any local setup:

1. **Click the badge**: [![Launch on Seqera Platform](https://img.shields.io/badge/launch%20on-seqera%20platform-blue.svg)](https://cloud.seqera.io/)
2. **Sign in** to your Seqera Platform account
3. **Configure parameters**:
   - Set your `BIOLMAI_TOKEN` as an environment variable
   - Choose your input mode (demo, default, or custom FASTA)
   - Configure compute resources
4. **Launch** the workflow

**Benefits of Seqera Platform:**
- No local installation required
- Scalable cloud compute resources
- Built-in monitoring and visualization
- Easy parameter configuration
- Automatic result management

## What This Example Does

This project demonstrates:
1. **Unified Workflow** (`intro.nf`): Single workflow that handles both demo and production use cases
2. **BioLM Integration**: Using ESMFold for protein structure prediction
3. **Nextflow Orchestration**: Parallel processing and workflow management
4. **PDB Output**: Direct extraction of protein structure files

## Prerequisites

1. **BioLM API Token**: Get your token from [BioLM](https://biolm.ai/)
2. **Python 3.7+**: With the BioLM SDK installed
3. **Nextflow**: Version 20.0 or later

## Workflow Modes

### Demo Mode (`--demo`)
- **Purpose**: Quick test with a hardcoded protein sequence
- **Input**: Built-in demo sequence (MKTVRQERLKSIVRILERSKEPVSGAQLAEELSVSRQVIVQDIAYLRSLGYNIVATPRGYVLAGG)
- **Output**: `DEMO.pdb`

### Default Mode (no parameters)
- **Purpose**: Standard example using GFP protein
- **Input**: Built-in GFP sequence
- **Output**: `GFP.pdb`

### Custom FASTA Mode (`--input`)
- **Purpose**: Process your own protein sequences
- **Input**: Your FASTA file
- **Output**: One `.pdb` file per sequence in the FASTA

## Project Structure

```
nf-biolm/
├── intro.nf              # Main workflow (unified)
├── nextflow.config       # Configuration
├── requirements.txt      # Python dependencies
├── tower.yml            # Seqera Platform configuration
├── README.md            # This file
├── results/             # Output directory
│   └── *.pdb           # Protein structure files
└── work/               # Nextflow work directory
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--token` | BioLM API token | `$BIOLMAI_TOKEN` env var |
| `--input` | Input FASTA file | None (uses default) |
| `--demo` | Run in demo mode | `false` |
| `--outdir` | Output directory | `results` |

## Output

The workflow produces **PDB structure files** directly:
- **Format**: Standard PDB format
- **Location**: `results/` directory
- **Naming**: Based on sequence ID from FASTA header

## Examples

### Demo Mode
```bash
nextflow run intro.nf --demo
# Output: results/DEMO.pdb
```

### Default Mode
```bash
nextflow run intro.nf
# Output: results/GFP.pdb
```

### Custom FASTA
```bash
nextflow run intro.nf --input my_proteins.fasta
# Output: results/sequence1.pdb, results/sequence2.pdb, etc.
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

- **API Token Issues**: Ensure `BIOLMAI_TOKEN` is set correctly
- **Import Error**: Run `pip install biolmai`
- **Workflow errors**: Check the `.nextflow.log` file for details
- **API Rate Limits**: BioLM has rate limits; wait between requests if needed

## Customization

The workflow can be easily customized by:
1. **Modifying sequences**: Edit the hardcoded sequences in the workflow
2. **Adding parameters**: Extend the parameter list for additional options
3. **Changing output format**: Modify the PDB extraction logic
