# nf-biolm: BioLM in Nextflow

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A5%2020.0.0-brightgreen.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/docker-%20%20%F0%9F%8C%A2%20%20run%20with%20docker-blue.svg)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/singularity-%20%20%F0%9F%8C%A2%20%20run%20with%20singularity-orange.svg)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/launch%20on-seqera%20platform-blue.svg)](https://cloud.seqera.io/)
[![BioLM SDK](https://img.shields.io/badge/biolm%20sdk-%E2%89%A5%200.1.0-green.svg)](https://github.com/BioLM/py-biolm)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive example demonstrating how to use the BioLM SDK within Nextflow pipelines for protein structure prediction and antibody engineering. This project provides two main workflows:

1. **`intro.nf`**: Protein structure prediction using ESMFold
2. **`antibody_engineering.nf`**: Antibody variant generation using AntiFold

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

   **Note**: The workflows include built-in token validation and will provide clear error messages if the token is missing or invalid.

### 3. Run the Workflows

#### **Protein Structure Prediction (`intro.nf`)**

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

#### **Antibody Engineering (`antibody_engineering.nf`)**

**Quick Start:**
```bash
nextflow run antibody_engineering.nf --num_variants 5
# Output: results/antibody_engineering_summary.html + analysis files
```

**With Custom Parameters:**
```bash
nextflow run antibody_engineering.nf \
  --num_variants 10 \
  --sampling_temp 0.8
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

## What These Examples Do

This project demonstrates two main use cases:

### **Protein Structure Prediction (`intro.nf`)**
1. **Unified Workflow**: Single workflow that handles both demo and production use cases
2. **ESMFold Integration**: Using BioLM's ESMFold for protein structure prediction
3. **Nextflow Orchestration**: Parallel processing and workflow management
4. **PDB Output**: Direct extraction of protein structure files

### **Antibody Engineering (`antibody_engineering.nf`)**
1. **AntiFold Integration**: Using BioLM's AntiFold for antibody variant generation
2. **Multi-Target Processing**: Handles EGFR, PDL1, MBP, and IL-7RALPHA targets
3. **CDR Analysis**: Comprehensive analysis of Complementarity-Determining Regions
4. **Automated PDB Download**: Downloads PDB files directly from RCSB
5. **Rich Reporting**: HTML summaries with diversity analysis and statistics

## Prerequisites

1. **BioLM API Token**: Get your token from [BioLM](https://biolm.ai/)
2. **Python 3.7+**: With the BioLM SDK installed
3. **Nextflow**: Version 20.0 or later

## Workflow Details

### **Protein Structure Prediction (`intro.nf`)**

#### Demo Mode (`--demo`)
- **Purpose**: Quick test with a hardcoded protein sequence
- **Input**: Built-in demo sequence (MKTVRQERLKSIVRILERSKEPVSGAQLAEELSVSRQVIVQDIAYLRSLGYNIVATPRGYVLAGG)
- **Output**: `DEMO.pdb`

#### Default Mode (no parameters)
- **Purpose**: Standard example using GFP protein
- **Input**: Built-in GFP sequence
- **Output**: `GFP.pdb`

#### Custom FASTA Mode (`--input`)
- **Purpose**: Process your own protein sequences
- **Input**: Your FASTA file
- **Output**: One `.pdb` file per sequence in the FASTA

### **Antibody Engineering (`antibody_engineering.nf`)**

#### What It Does
- **Downloads PDB files** from RCSB (3c09, 5x8m, 5bjz, 6p67)
- **Extracts sequences** from heavy, light, and antigen chains
- **Generates variants** using AntiFold for CDR regions
- **Analyzes diversity** of generated antibody variants
- **Creates reports** with statistics and visualizations

#### Output Files
- **PDB files**: Downloaded antibody structures
- **Sequence files**: Extracted chain sequences
- **Variant files**: Generated antibody variants
- **Analysis files**: CDR diversity analysis
- **HTML report**: Comprehensive summary with statistics

## Project Structure

```
nf-biolm/
├── intro.nf                    # Protein structure prediction workflow
├── antibody_engineering.nf     # Antibody engineering workflow
├── antibody_engineering_test.nf # Test version (mock data)
├── nextflow.config            # Configuration
├── requirements.txt           # Python dependencies
├── tower.yml                 # Seqera Platform configuration
├── LICENSE                   # MIT License
├── README.md                 # This file
├── results/                  # Output directory
│   ├── *.pdb                # Protein structure files
│   ├── analysis/            # Antibody analysis results
│   ├── sequences/           # Extracted sequences
│   ├── variants/            # Generated variants
│   └── *.html               # Summary reports
└── work/                    # Nextflow work directory
```

## Parameters

### **Protein Structure Prediction (`intro.nf`)**

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--token` | BioLM API token | `$BIOLMAI_TOKEN` env var |
| `--input` | Input FASTA file | None (uses default) |
| `--demo` | Run in demo mode | `false` |
| `--outdir` | Output directory | `results` |

### **Antibody Engineering (`antibody_engineering.nf`)**

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--token` | BioLM API token | `$BIOLMAI_TOKEN` env var |
| `--num_variants` | Number of variants per target | `100` |
| `--sampling_temp` | Sampling temperature for generation | `0.8` |
| `--outdir` | Output directory | `results` |

## Output

### **Protein Structure Prediction (`intro.nf`)**
The workflow produces **PDB structure files** directly:
- **Format**: Standard PDB format
- **Location**: `results/` directory
- **Naming**: Based on sequence ID from FASTA header

### **Antibody Engineering (`antibody_engineering.nf`)**
The workflow produces comprehensive analysis results:
- **PDB files**: Downloaded antibody structures
- **Sequence files**: Extracted chain sequences (JSON format)
- **Variant files**: Generated antibody variants (JSON format)
- **Analysis files**: CDR diversity analysis (JSON + CSV)
- **HTML report**: Interactive summary with statistics and visualizations

## What You Get

### **Protein Structure Prediction (`intro.nf`)**
- **PDB Files**: Standard protein structure files ready for visualization
- **Clean Output**: No intermediate JSON files, just the structures you need
- **Scalable**: Can process single sequences or entire FASTA files

### **Antibody Engineering (`antibody_engineering.nf`)**
- **Multi-Target Analysis**: EGFR, PDL1, MBP, and IL-7RALPHA antibody targets
- **CDR Diversity**: Comprehensive analysis of antibody diversity
- **Professional Reports**: HTML summaries with statistics and visualizations
- **Complete Pipeline**: From PDB download to final analysis
- **Real BioLM Integration**: Uses actual AntiFold API for variant generation

## Next Steps

### **For Protein Structure Prediction**
- **Visualize**: Open PDB files in tools like PyMOL, Chimera, or online viewers
- **Customize**: Modify the workflow for your specific needs
- **Scale Up**: Process larger datasets with more compute resources

### **For Antibody Engineering**
- **Analyze Results**: Review the HTML summary and diversity analysis
- **Explore Variants**: Examine generated antibody sequences and their properties
- **Customize Targets**: Modify the workflow to work with your own antibody targets
- **Production Use**: Scale up for large-scale antibody engineering projects

## Troubleshooting

- **API Token Issues**: Ensure `BIOLMAI_TOKEN` is set correctly. The workflows now include graceful token validation and will provide clear error messages if the token is missing.
- **Import Error**: Run `pip install biolmai`
- **Workflow errors**: Check the `.nextflow.log` file for details
- **API Rate Limits**: BioLM has rate limits; wait between requests if needed

## Customization

The workflow can be easily customized by:
1. **Modifying sequences**: Edit the hardcoded sequences in the workflow
2. **Adding parameters**: Extend the parameter list for additional options
3. **Changing output format**: Modify the PDB extraction logic

## Related Resources

- **Blog Post**: [Scaling BioLM Workflows with Nextflow: From Notebooks to Production Pipelines](https://blog.biolm.ai/scaling-biolm-workflows-with-nextflow/) - Learn more about integrating BioLM with Nextflow workflows
- **BioLM Documentation**: [https://biolm.ai/](https://biolm.ai/) - Official BioLM platform and API documentation
- **Nextflow Documentation**: [https://www.nextflow.io/](https://www.nextflow.io/) - Nextflow workflow framework documentation
- **Seqera Platform**: [https://cloud.seqera.io/](https://cloud.seqera.io/) - Cloud-native platform for running Nextflow workflows