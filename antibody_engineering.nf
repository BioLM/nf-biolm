#!/usr/bin/env nextflow

/*
 * BioLM Antibody Engineering Workflow
 * 
 * Based on the BioLM Antibody Engineering notebook protocol.
 * Generates antibody variants using AntiFold and analyzes CDR diversity.
 */

nextflow.enable.dsl = 2

// Parameters
params.token = params.token ?: System.getenv('BIOLMAI_TOKEN') ?: ''
params.num_variants = params.num_variants ?: 100
params.sampling_temp = params.sampling_temp ?: 0.8
params.outdir = params.outdir ?: 'results'

/*
 * Download PDB files from RCSB
 */
process download_pdbs {
    tag "Downloading PDB files"
    publishDir "${params.outdir}/pdbs", mode: 'copy'

    output:
    path "*.pdb"
    path "target_mapping.json"

    script:
    """
    #!/usr/bin/env python3
    import json
    import os
    import requests

    # Target mapping based on PDB IDs
    target_mapping = {
        '3c09': 'EGFR',
        '5x8m': 'PDL1', 
        '5bjz': 'MBP',
        '6p67': 'IL-7RALPHA'
    }

    # Download PDB files
    mapping = {}
    for pdb_id, target in target_mapping.items():
        url = f"https://files.rcsb.org/download/{pdb_id}.pdb"
        filename = f"{pdb_id}.pdb"
        
        print(f"Downloading {pdb_id}.pdb ({target})...")
        response = requests.get(url)
        
        if response.status_code == 200:
            with open(filename, "w") as f:
                f.write(response.text)
            mapping[target] = filename
            print(f"✓ Downloaded {filename}")
        else:
            print(f"✗ Failed to download {filename}")

    # Save mapping
    with open("target_mapping.json", "w") as f:
        json.dump(mapping, f, indent=2)

    print(f"Downloaded PDBs for targets: {list(mapping.keys())}")
    """
}

/*
 * Extract sequences from PDB files
 */
process extract_sequences {
    tag "Extracting sequences"
    publishDir "${params.outdir}/sequences", mode: 'copy'

    input:
    path pdb_files
    path mapping_file

    output:
    path "*.json"

    script:
    """
    #!/usr/bin/env python3
    import json
    import os
    from biotite.structure.io.pdb import PDBFile, get_structure
    from biotite.structure.residues import get_residues
    from biotite.structure.info import one_letter_code
    from io import StringIO

    # Valid residues
    VALID_RESIDUES = {
        "ALA", "ARG", "ASN", "ASP", "CYS", "GLN", "GLU", "GLY",
        "HIS", "ILE", "LEU", "LYS", "MET", "PHE", "PRO", "SER",
        "THR", "TRP", "TYR", "VAL"
    }

    def extract_sequences_from_pdb_str(pdb_str, chain_ids):
        pdbf = PDBFile.read(StringIO(pdb_str))
        structure = get_structure(pdbf, model=1)
        
        seqs = {}
        for chain in chain_ids:
            chain_array = structure[structure.chain_id == chain]
            if chain_array.array_length() == 0:
                continue
                
            res_ids, res_names = get_residues(chain_array)
            if len(res_ids) == 0:
                continue
                
            seq = ''
            for name in res_names:
                if name in VALID_RESIDUES:
                    seq += one_letter_code(name)
            seqs[chain] = seq
        
        return seqs

    # Target mapping based on PDB IDs
    target_mapping = {
        '3c09': 'EGFR',
        '5x8m': 'PDL1', 
        '5bjz': 'MBP',
        '6p67': 'IL-7RALPHA'
    }

    # Chain definitions for each target
    target_chains = {
        "EGFR": ['H', 'L', 'D'],
        "PDL1": ['B', 'C', 'A'], 
        "MBP": ['C', 'L', 'A'],
        "IL-7RALPHA": ['A', 'B', 'K']
    }

    # Process each PDB file
    pdb_files_list = "${pdb_files}".split()
    for pdb_file in pdb_files_list:
        if pdb_file.endswith('.pdb'):
            # Determine target
            target = None
            for pdb_id, target_name in target_mapping.items():
                if pdb_id in pdb_file:
                    target = target_name
                    break
            
            if target:
                # Read PDB file
                with open(pdb_file, "r") as f:
                    pdb_str = f.read()

                # Extract sequences
                chains = target_chains[target]
                sequences = extract_sequences_from_pdb_str(pdb_str, chains)
                
                # Save sequences
                with open(f"{target}_sequences.json", "w") as f:
                    json.dump(sequences, f, indent=2)

                print(f"Extracted sequences for {target}: {list(sequences.keys())}")
    """
}

/*
 * Generate antibody variants using AntiFold
 */
process generate_variants {
    tag "Generating variants"
    publishDir "${params.outdir}/variants", mode: 'copy'

    input:
    path sequence_files
    path pdb_files

    output:
    path "*.json"

    script:
    """
    #!/usr/bin/env python3
    import json
    import time
    import os
    import sys
    from biolmai import BioLM

    # Check if API token is provided
    # Try parameter first, then environment variable
    token = "${params.token}" if "${params.token}".strip() else os.getenv('BIOLMAI_TOKEN', '')
    if not token.strip():
        print("ERROR: BioLM API token is not set!")
        print("Please set your BIOLMAI_TOKEN environment variable or use --token parameter")
        print("Get your token from: https://biolm.ai/")
        sys.exit(1)

    # Target mapping based on PDB IDs
    target_mapping = {
        '3c09': 'EGFR',
        '5x8m': 'PDL1', 
        '5bjz': 'MBP',
        '6p67': 'IL-7RALPHA'
    }

    # Chain definitions for each target
    target_chains = {
        "EGFR": {"light_chain": "L", "heavy_chain": "H", "antigen_chain": "D"},
        "PDL1": {"light_chain": "C", "heavy_chain": "B", "antigen_chain": "A"},
        "MBP": {"light_chain": "L", "heavy_chain": "C", "antigen_chain": "A"},
        "IL-7RALPHA": {"light_chain": "B", "heavy_chain": "A", "antigen_chain": "K"}
    }

    # Process each sequence file
    seq_files_list = "${sequence_files}".split()
    for seq_file in seq_files_list:
        if seq_file.endswith('_sequences.json'):
            target = seq_file.replace('_sequences.json', '')
            
            # Find corresponding PDB file
            pdb_file = None
            pdb_files_list = "${pdb_files}".split()
            for pdb_id, target_name in target_mapping.items():
                if target_name == target:
                    for pdb_file_path in pdb_files_list:
                        if pdb_id in pdb_file_path:
                            pdb_file = pdb_file_path
                            break
                    break
            
            if pdb_file and os.path.exists(pdb_file):
                # Read PDB file
                with open(pdb_file, "r") as f:
                    pdb_str = f.read()

                chains = target_chains[target]

                # Prepare payload for AntiFold
                payload = {
                    "params": {
                        "num_seq_per_target": ${params.num_variants},
                        "sampling_temp": ${params.sampling_temp},
                        "regions": ["CDR1", "CDR2", "CDR3"],
                        "light_chain": chains["light_chain"],
                        "heavy_chain": chains["heavy_chain"],
                        "antigen_chain": chains["antigen_chain"]
                    },
                    "items": [{"pdb": pdb_str}]
                }

                # Generate variants
                start = time.time()
                result = BioLM(
                    entity="antifold",
                    action="generate",
                    items=payload["items"],
                    params=payload["params"],
                    api_key=token
                )
                end = time.time()

                # Save results
                with open(f"{target}_variants.json", "w") as f:
                    json.dump(result, f, indent=2)

                print(f"Generated {len(result['sequences'])} variants for {target} in {end - start:.2f} seconds")
    """
}

/*
 * Extract CDRs and analyze diversity
 */
process analyze_cdrs {
    tag "Analyzing CDRs"
    publishDir "${params.outdir}/analysis", mode: 'copy'

    input:
    path variant_files

    output:
    path "*.json"
    path "*.csv"

    script:
    """
    #!/usr/bin/env python3
    import json
    import pandas as pd
    import os
    
    def extract_cdrs_simple(seq, chain_type='heavy'):
        # Simple complementarity determining region extraction based on IMGT numbering positions
        # This is a fallback when abnumber is not available
        if not seq or len(seq) < 50:
            return {'cdr1': None, 'cdr2': None, 'cdr3': None}
        
        try:
            # Approximate complementarity determining region positions based on IMGT numbering
            # These are rough estimates and may not be 100% accurate
            if chain_type == 'heavy':
                # Heavy chain complementarity determining region positions (approximate)
                cdr1_start, cdr1_end = 26, 35  # region 1
                cdr2_start, cdr2_end = 52, 66  # region 2  
                cdr3_start, cdr3_end = 99, 106 # region 3
            else:
                # Light chain complementarity determining region positions (approximate)
                cdr1_start, cdr1_end = 24, 34  # region 1
                cdr2_start, cdr2_end = 50, 56  # region 2
                cdr3_start, cdr3_end = 89, 97  # region 3
            
            # Extract complementarity determining regions with bounds checking
            cdr1 = seq[cdr1_start:cdr1_end] if len(seq) > cdr1_end else None
            cdr2 = seq[cdr2_start:cdr2_end] if len(seq) > cdr2_end else None
            cdr3 = seq[cdr3_start:cdr3_end] if len(seq) > cdr3_end else None
            
            return {
                'cdr1': cdr1,
                'cdr2': cdr2,
                'cdr3': cdr3
            }
        except Exception as e:
            print(f"Failed to extract CDRs: {e}")
            return {'cdr1': None, 'cdr2': None, 'cdr3': None}
    
    def extract_cdrs(seq, scheme='chothia'):
        # Try abnumber first, fallback to simple complementarity determining region extraction
        if not seq:
            return {'cdr1': None, 'cdr2': None, 'cdr3': None}
        
        try:
            from abnumber import Chain
            chain = Chain(seq, scheme=scheme)
            return {
                'cdr1': chain.cdr1_seq,
                'cdr2': chain.cdr2_seq,
                'cdr3': chain.cdr3_seq
            }
        except ImportError:
            print("abnumber not available, using simple CDR extraction")
            chain_type = 'heavy' if len(seq) > 200 else 'light'  # rough heuristic
            return extract_cdrs_simple(seq, chain_type)
        except Exception as e:
            print(f"abnumber failed: {e}, using simple CDR extraction")
            chain_type = 'heavy' if len(seq) > 200 else 'light'
            return extract_cdrs_simple(seq, chain_type)

    # Process each variant file
    var_files_list = "${variant_files}".split()
    for var_file in var_files_list:
        if var_file.endswith('_variants.json'):
            target = var_file.replace('_variants.json', '')
            
            # Load variants
            with open(var_file, "r") as f:
                variants_data = json.load(f)

            # Convert to DataFrame
            df = pd.DataFrame(variants_data['sequences'])
            df['target'] = target

            # Extract CDRs
            cdr_data = []
            for _, row in df.iterrows():
                heavy_cdrs = extract_cdrs(row.get('heavy'))
                light_cdrs = extract_cdrs(row.get('light'))

                cdr_data.append({
                    'heavy_cdr1': heavy_cdrs['cdr1'],
                    'heavy_cdr2': heavy_cdrs['cdr2'],
                    'heavy_cdr3': heavy_cdrs['cdr3'],
                    'light_cdr1': light_cdrs['cdr1'],
                    'light_cdr2': light_cdrs['cdr2'],
                    'light_cdr3': light_cdrs['cdr3'],
                })

            cdr_df = pd.DataFrame(cdr_data)
            df_with_cdrs = pd.concat([df.reset_index(drop=True), cdr_df], axis=1)

            # Analyze CDR diversity
            cdr_columns = ['heavy_cdr1', 'heavy_cdr2', 'heavy_cdr3', 'light_cdr1', 'light_cdr2', 'light_cdr3']
            diversity_analysis = {}
            
            for col in cdr_columns:
                unique_count = df_with_cdrs[col].nunique()
                total_count = len(df_with_cdrs)
                diversity_analysis[col] = {
                    'unique_count': unique_count,
                    'total_count': total_count,
                    'diversity_ratio': unique_count / total_count if total_count > 0 else 0
                }

            # Save results
            df_with_cdrs.to_csv(f"{target}_variants.csv", index=False)
            
            analysis_result = {
                'target': target,
                'total_variants': len(df_with_cdrs),
                'cdr_diversity': diversity_analysis,
                'summary_stats': {
                    'avg_score': df_with_cdrs['score'].mean() if 'score' in df_with_cdrs.columns else None,
                    'avg_global_score': df_with_cdrs['global_score'].mean() if 'global_score' in df_with_cdrs.columns else None,
                    'avg_mutations': df_with_cdrs['mutations'].mean() if 'mutations' in df_with_cdrs.columns else None
                }
            }

            with open(f"{target}_cdr_analysis.json", "w") as f:
                json.dump(analysis_result, f, indent=2)

            print(f"Analyzed CDRs for {target}: {len(df_with_cdrs)} variants")
    """
}

/*
 * Create plots and visualizations (like the notebook)
 */
process create_plots {
    tag "Creating plots"
    publishDir "${params.outdir}/plots", mode: 'copy'

    input:
    path analysis_files
    path csv_files

    output:
    path "*.png"
    path "*.html"

    script:
    """
    #!/usr/bin/env python3
    import json
    import pandas as pd
    import matplotlib.pyplot as plt
    import seaborn as sns
    import numpy as np
    import glob
    import os

    # Set style
    plt.style.use('default')
    sns.set_palette("husl")

    # Collect all variant data with CDRs
    all_variants = []
    
    for analysis_file in glob.glob("*.json"):
        if "cdr_analysis" in analysis_file:
            target = analysis_file.replace("_cdr_analysis.json", "")
            
            # Look for corresponding CSV file
            csv_file = f"{target}_variants.csv"
            if os.path.exists(csv_file):
                df = pd.read_csv(csv_file)
                all_variants.append(df)
                print(f"Loaded {len(df)} variants for {target}")
            else:
                print(f"CSV file not found: {csv_file}")
                # List all files in current directory for debugging
                print("Available files:", os.listdir("."))
    
    if not all_variants:
        print("No variant data found for plotting")
        # Create empty plots
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.text(0.5, 0.5, 'No data available for plotting', 
                ha='center', va='center', transform=ax.transAxes)
        plt.savefig("no_data_plot.png", dpi=150, bbox_inches='tight')
        plt.close()
        exit(0)
    
    # Combine all variants
    combined_df = pd.concat(all_variants, ignore_index=True)
    print(f"Total variants for plotting: {len(combined_df)}")

    # 1. CDR Diversity Bar Plot
    if 'heavy_cdr1' in combined_df.columns:
        # Prepare data for CDR diversity plot
        cdr_columns = ['heavy_cdr1', 'heavy_cdr2', 'heavy_cdr3', 'light_cdr1', 'light_cdr2', 'light_cdr3']
        cdr_data = []
        
        for col in cdr_columns:
            if col in combined_df.columns:
                unique_count = combined_df[col].nunique()
                chain = 'Heavy' if 'heavy' in col else 'Light'
                cdr_num = col.split('_')[-1].replace('cdr', 'CDR')
                
                cdr_data.append({
                    'CDR': cdr_num,
                    'Chain': chain,
                    'Unique_Count': unique_count
                })
        
        if cdr_data:
            cdr_counts_df = pd.DataFrame(cdr_data)
            
            plt.figure(figsize=(10, 6))
            sns.barplot(data=cdr_counts_df, x='CDR', y='Unique_Count', hue='Chain')
            plt.title('Number of Unique CDR Sequences by Region and Chain')
            plt.ylabel('Unique Sequence Count')
            plt.xlabel('CDR Region')
            plt.legend(title='Chain')
            plt.tight_layout()
            plt.savefig("cdr_diversity_plot.png", dpi=150, bbox_inches='tight')
            plt.close()
            print("Created CDR diversity plot")

    # 2. Feature Pairplot
    features = ['global_score', 'score', 'mutations', 'seq_recovery']
    available_features = [f for f in features if f in combined_df.columns]
    
    if len(available_features) > 1 and 'target' in combined_df.columns:
        plt.figure(figsize=(12, 10))
        
        # Create a grid of subplots for pairwise relationships
        n_features = len(available_features)
        fig, axes = plt.subplots(n_features, n_features, figsize=(15, 15))
        
        if n_features == 1:
            axes = [[axes]]
        elif n_features == 2:
            axes = [axes]
        
        for i, feat1 in enumerate(available_features):
            for j, feat2 in enumerate(available_features):
                ax = axes[i][j] if n_features > 1 else axes[i]
                
                if i == j:
                    # Diagonal: histogram
                    for target in combined_df['target'].unique():
                        data = combined_df[combined_df['target'] == target][feat1]
                        ax.hist(data, alpha=0.7, label=target, bins=20)
                    ax.set_xlabel(feat1)
                    ax.set_ylabel('Count')
                    ax.legend()
                else:
                    # Off-diagonal: scatter plot
                    for target in combined_df['target'].unique():
                        data = combined_df[combined_df['target'] == target]
                        ax.scatter(data[feat2], data[feat1], alpha=0.7, label=target, s=20)
                    ax.set_xlabel(feat2)
                    ax.set_ylabel(feat1)
                    if i == 0 and j == n_features-1:  # Only show legend on top-right
                        ax.legend()
        
        plt.suptitle('Feature Relationships Across Targets', fontsize=16)
        plt.tight_layout()
        plt.savefig("feature_pairplot.png", dpi=150, bbox_inches='tight')
        plt.close()
        print("Created feature pairplot")

    # 3. Individual target plots
    for target in combined_df['target'].unique():
        target_data = combined_df[combined_df['target'] == target]
        
        # Score distribution
        plt.figure(figsize=(12, 4))
        
        plt.subplot(1, 3, 1)
        plt.hist(target_data['score'], bins=20, alpha=0.7, color='skyblue')
        plt.title(f'{target} - Score Distribution')
        plt.xlabel('Score')
        plt.ylabel('Count')
        
        plt.subplot(1, 3, 2)
        plt.hist(target_data['global_score'], bins=20, alpha=0.7, color='lightgreen')
        plt.title(f'{target} - Global Score Distribution')
        plt.xlabel('Global Score')
        plt.ylabel('Count')
        
        plt.subplot(1, 3, 3)
        plt.hist(target_data['mutations'], bins=20, alpha=0.7, color='salmon')
        plt.title(f'{target} - Mutations Distribution')
        plt.xlabel('Number of Mutations')
        plt.ylabel('Count')
        
        plt.tight_layout()
        plt.savefig(f"{target}_distributions.png", dpi=150, bbox_inches='tight')
        plt.close()
        print(f"Created distribution plots for {target}")

    # 4. Create an interactive HTML report
    html_content = f'''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Antibody Engineering Analysis Plots</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; }}
            .plot {{ margin: 20px 0; text-align: center; }}
            .plot img {{ max-width: 100%; height: auto; border: 1px solid #ddd; }}
            h1, h2 {{ color: #333; }}
            .summary {{ background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0; }}
        </style>
    </head>
    <body>
        <h1>Antibody Engineering Analysis Plots</h1>
        
        <div class="summary">
            <h2>Summary</h2>
            <p><strong>Total Variants:</strong> {len(combined_df)}</p>
            <p><strong>Targets:</strong> {', '.join(combined_df['target'].unique())}</p>
            <p><strong>Average Score:</strong> {combined_df['score'].mean():.3f}</p>
            <p><strong>Average Global Score:</strong> {combined_df['global_score'].mean():.3f}</p>
            <p><strong>Average Mutations:</strong> {combined_df['mutations'].mean():.1f}</p>
        </div>
    '''
    
    # Add plots to HTML
    plot_files = glob.glob("*.png")
    for plot_file in sorted(plot_files):
        html_content += f'''
        <div class="plot">
            <h2>{plot_file.replace('.png', '').replace('_', ' ').title()}</h2>
            <img src="{plot_file}" alt="{plot_file}">
        </div>
        '''
    
    html_content += '''
    </body>
    </html>
    '''
    
    with open("plots_report.html", "w") as f:
        f.write(html_content)
    
    print("Created interactive plots report")
    print(f"Generated {len(plot_files)} plot files")
    """
}

/*
 * Create CSV output with CDR data (like the notebook)
 */
process create_csv_output {
    tag "Creating CSV output"
    publishDir "${params.outdir}/csv", mode: 'copy'

    input:
    path analysis_files

    output:
    path "variant_candidates.csv"

    script:
    """
    #!/usr/bin/env python3
    import json
    import pandas as pd
    import glob
    import os

    # Collect all variant data with CDRs
    all_variants = []
    
    for analysis_file in glob.glob("*.json"):
        if "cdr_analysis" in analysis_file:
            target = analysis_file.replace("_cdr_analysis.json", "")
            
            # Look for corresponding CSV file
            csv_file = f"{target}_variants.csv"
            if os.path.exists(csv_file):
                df = pd.read_csv(csv_file)
                all_variants.append(df)
                print(f"Loaded {len(df)} variants for {target}")
    
    if all_variants:
        # Combine all variants
        combined_df = pd.concat(all_variants, ignore_index=True)
        
        # Select the same columns as the notebook
        output_columns = [
            "heavy", "light", "global_score", "score", "mutations", "seq_recovery", "target",
            "heavy_cdr1", "heavy_cdr2", "heavy_cdr3", "light_cdr1", "light_cdr2", "light_cdr3"
        ]
        
        # Only include columns that exist
        available_columns = [col for col in output_columns if col in combined_df.columns]
        final_df = combined_df[available_columns]
        
        # Save to CSV
        final_df.to_csv("variant_candidates.csv", index=False)
        print(f"Created variant_candidates.csv with {len(final_df)} variants")
        print(f"Columns: {list(final_df.columns)}")
    else:
        print("No variant data found")
        # Create empty CSV with expected columns
        empty_df = pd.DataFrame(columns=[
            "heavy", "light", "global_score", "score", "mutations", "seq_recovery", "target",
            "heavy_cdr1", "heavy_cdr2", "heavy_cdr3", "light_cdr1", "light_cdr2", "light_cdr3"
        ])
        empty_df.to_csv("variant_candidates.csv", index=False)
    """
}

/*
 * Create summary report
 */
process create_summary {
    tag "Creating summary report"
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path analysis_files

    output:
    path "antibody_engineering_summary.html"

    script:
    """
    #!/usr/bin/env python3
    import json
    import glob
    import pandas as pd
    import os

    # Collect all analysis results
    all_results = []
    for analysis_file in glob.glob("*.json"):
        if "cdr_analysis" in analysis_file:
            with open(analysis_file, "r") as f:
                result = json.load(f)
                all_results.append(result)

    # Pre-calculate formatted values for each result
    formatted_results = []
    for result in all_results:
        avg_score = f"{result['summary_stats']['avg_score']:.3f}" if result['summary_stats']['avg_score'] is not None else 'N/A'
        avg_global_score = f"{result['summary_stats']['avg_global_score']:.3f}" if result['summary_stats']['avg_global_score'] is not None else 'N/A'
        avg_mutations = f"{result['summary_stats']['avg_mutations']:.1f}" if result['summary_stats']['avg_mutations'] is not None else 'N/A'
        
        formatted_results.append({
            'result': result,
            'avg_score': avg_score,
            'avg_global_score': avg_global_score,
            'avg_mutations': avg_mutations
        })

    # Create summary HTML
    html_content = '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>BioLM Antibody Engineering Summary</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .target { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
            .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; margin: 10px 0; }
            .stat { background: #f5f5f5; padding: 10px; border-radius: 3px; }
            table { width: 100%; border-collapse: collapse; margin: 10px 0; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
        </style>
    </head>
    <body>
        <h1>BioLM Antibody Engineering Summary</h1>
        <p>Generated variants for ''' + str(len(all_results)) + ''' targets using AntiFold</p>
    '''

    for formatted in formatted_results:
        result = formatted['result']
        html_content += f'''
        <div class="target">
            <h2>{result['target']}</h2>
            <div class="stats">
                <div class="stat"><strong>Total Variants:</strong> {result['total_variants']}</div>
                <div class="stat"><strong>Avg Score:</strong> {formatted['avg_score']}</div>
                <div class="stat"><strong>Avg Global Score:</strong> {formatted['avg_global_score']}</div>
                <div class="stat"><strong>Avg Mutations:</strong> {formatted['avg_mutations']}</div>
            </div>
            
            <h3>CDR Diversity Analysis</h3>
            <table>
                <tr><th>CDR Region</th><th>Unique Variants</th><th>Diversity Ratio</th></tr>
        '''
        
        for cdr, stats in result['cdr_diversity'].items():
            html_content += f'''
                <tr>
                    <td>{cdr}</td>
                    <td>{stats['unique_count']}</td>
                    <td>{stats['diversity_ratio']:.2f}</td>
                </tr>
            '''
        
        html_content += '</table></div>'

    html_content += '''
    </body>
    </html>
    '''

    with open("antibody_engineering_summary.html", "w") as f:
        f.write(html_content)

    print(f"Created summary report for {len(all_results)} targets")
    """
}

/*
 * Workflow definition
 */
workflow {
    // Download PDB files
    download_pdbs()
    
    // Extract sequences for each target
    extract_sequences(download_pdbs.out[0], download_pdbs.out[1])
    
    // Generate variants
    generate_variants(extract_sequences.out, download_pdbs.out[0])
    
    // Analyze CDRs
    analyze_cdrs(generate_variants.out)
    
    // Create plots and visualizations (like the notebook)
    create_plots(analyze_cdrs.out[0], analyze_cdrs.out[1])
    
    // Create CSV output (like the notebook)
    create_csv_output(analyze_cdrs.out[0])
    
    // Create summary
    create_summary(analyze_cdrs.out[0])
}
