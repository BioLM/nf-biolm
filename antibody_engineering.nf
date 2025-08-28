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
    from biolmai import BioLM

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
                    api_key="${params.token}"
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
    from abnumber import Chain

    def extract_cdrs(seq, scheme='chothia'):
        if not seq:
            return {'cdr1': None, 'cdr2': None, 'cdr3': None}
        try:
            chain = Chain(seq, scheme=scheme)
            return {
                'cdr1': chain.cdr1_seq,
                'cdr2': chain.cdr2_seq,
                'cdr3': chain.cdr3_seq
            }
        except Exception as e:
            print(f"Failed to extract CDRs: {e}")
            return {'cdr1': None, 'cdr2': None, 'cdr3': None}

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
    
    // Create summary
    create_summary(analyze_cdrs.out[0])
}
