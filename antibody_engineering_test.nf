#!/usr/bin/env nextflow

/*
 * BioLM Antibody Engineering Test Workflow
 * 
 * Simplified test version that doesn't require PDB files
 */

nextflow.enable.dsl = 2

// Parameters
params.token = params.token ?: System.getenv('BIOLMAI_TOKEN') ?: ''
params.num_variants = params.num_variants ?: 5  // Small number for testing
params.sampling_temp = params.sampling_temp ?: 0.8
params.outdir = params.outdir ?: 'results'

/*
 * Create test PDB data
 */
process create_test_pdb {
    tag "Creating test PDB data"
    publishDir "${params.outdir}/pdbs", mode: 'copy'

    output:
    path "*.pdb"

    script:
    """
    #!/usr/bin/env python3
    
    # Create a simple test PDB file for EGFR
    pdb_content = "ATOM      1  N   ALA A   1      27.462  14.105   5.468  1.00 20.00           N\\n"
    pdb_content += "ATOM      2  CA  ALA A   1      26.525  13.000   5.000  1.00 20.00           C\\n"
    pdb_content += "ATOM      3  C   ALA A   1      25.000  13.000   5.000  1.00 20.00           C\\n"
    pdb_content += "ATOM      4  O   ALA A   1      24.500  12.000   5.000  1.00 20.00           O\\n"
    pdb_content += "ATOM      5  CB  ALA A   1      27.000  12.000   4.000  1.00 20.00           C\\n"
    pdb_content += "ATOM      6  N   ARG B   1      27.462  14.105   5.468  1.00 20.00           N\\n"
    pdb_content += "ATOM      7  CA  ARG B   1      26.525  13.000   5.000  1.00 20.00           C\\n"
    pdb_content += "ATOM      8  C   ARG B   1      25.000  13.000   5.000  1.00 20.00           C\\n"
    pdb_content += "ATOM      9  O   ARG B   1      24.500  12.000   5.000  1.00 20.00           O\\n"
    pdb_content += "ATOM     10  CB  ARG B   1      27.000  12.000   4.000  1.00 20.00           C\\n"
    pdb_content += "ATOM     11  N   ASN C   1      27.462  14.105   5.468  1.00 20.00           N\\n"
    pdb_content += "ATOM     12  CA  ASN C   1      26.525  13.000   5.000  1.00 20.00           C\\n"
    pdb_content += "ATOM     13  C   ASN C   1      25.000  13.000   5.000  1.00 20.00           C\\n"
    pdb_content += "ATOM     14  O   ASN C   1      24.500  12.000   5.000  1.00 20.00           O\\n"
    pdb_content += "ATOM     15  CB  ASN C   1      27.000  12.000   4.000  1.00 20.00           C\\n"
    pdb_content += "ATOM     16  N   ASP D   1      27.462  14.105   5.468  1.00 20.00           N\\n"
    pdb_content += "ATOM     17  CA  ASP D   1      26.525  13.000   5.000  1.00 20.00           C\\n"
    pdb_content += "ATOM     18  C   ASP D   1      25.000  13.000   5.000  1.00 20.00           C\\n"
    pdb_content += "ATOM     19  O   ASP D   1      24.500  12.000   5.000  1.00 20.00           O\\n"
    pdb_content += "ATOM     20  CB  ASP D   1      27.000  12.000   4.000  1.00 20.00           C\\n"
    pdb_content += "TER\\n"
    pdb_content += "END\\n"
    
    with open("3c09_test.pdb", "w") as f:
        f.write(pdb_content)
    
    print("Created test PDB file: 3c09_test.pdb")
    """
}

/*
 * Extract sequences from test PDB
 */
process extract_test_sequences {
    tag "Extracting test sequences"
    publishDir "${params.outdir}/sequences", mode: 'copy'

    input:
    path pdb_file

    output:
    path "*.json"

    script:
    """
    #!/usr/bin/env python3
    import json
    
    # Create mock sequences for testing
    test_sequences = {
        "EGFR": {
            "H": "QVQLVQSGAEVKKPGASVKVSCKASGYTFTNYWMNWVKQAPGQGLEWIGYINPYNDGTKYNEKFKGKATLTADKSSSTAYMQLSSLTSEDSAVYYCARYYDDHYCLDYWGQGTTLTVSS",
            "L": "DIQMTQSPSSLSASVGDRVTITCSASSSVSYMHWYQQKPGKAPKPLIYAPSNLASGVPSRFSGSGSGTDFTLTISSLQPEDFATYYCQQWSSNPPTFGQGTKVEIK",
            "D": "KKVCNGIGIGEFKDSLSINATNIKHFKNCTSISGDLHILPVAFRGDSFTHTPPLDPQELDILKTVKEITGFLLIQAWPENRTDLHAFENLEIIRGRTKQHGQFSLAVVSLNITSLGLRSLKEISDGDVIISGNKNLCYANTINWKKLFGTSGQKTKIPS"
        }
    }
    
    # Save sequences
    for target, sequences in test_sequences.items():
        with open(f"{target}_sequences.json", "w") as f:
            json.dump(sequences, f, indent=2)
    
    print("Extracted test sequences for EGFR")
    """
}

/*
 * Generate test variants
 */
process generate_test_variants {
    tag "Generating test variants"
    publishDir "${params.outdir}/variants", mode: 'copy'

    input:
    path sequence_file

    output:
    path "*.json"

    script:
    """
    #!/usr/bin/env python3
    import json
    import random
    import sys
    import os

    # Check if API token is provided (for consistency, even though this is a test with mock data)
    # Try parameter first, then environment variable
    token = "${params.token}" if "${params.token}".strip() else os.getenv('BIOLMAI_TOKEN', '')
    if not token.strip():
        print("ERROR: BioLM API token is not set!")
        print("Please set your BIOLMAI_TOKEN environment variable or use --token parameter")
        print("Get your token from: https://biolm.ai/")
        print("Note: This test workflow uses mock data, but token validation is included for consistency")
        sys.exit(1)
    
    # Create mock variant data for testing
    mock_variants = {
        "sequences": []
    }
    
    # Generate 5 mock variants
    for i in range(${params.num_variants}):
        variant = {
            "heavy": "QVQLVQSGAEVKKPGASVKVSCKASGYTFTNYWMNWVKQAPGQGLEWIGYINPYNDGTKYNEKFKGKATLTADKSSSTAYMQLSSLTSEDSAVYYCARYYDDHYCLDYWGQGTTLTVSS",
            "light": "DIQMTQSPSSLSASVGDRVTITCSASSSVSYMHWYQQKPGKAPKPLIYAPSNLASGVPSRFSGSGSGTDFTLTISSLQPEDFATYYCQQWSSNPPTFGQGTKVEIK",
            "score": random.uniform(0.7, 0.9),
            "global_score": random.uniform(0.6, 0.8),
            "mutations": random.randint(5, 15),
            "seq_recovery": random.uniform(0.85, 0.95)
        }
        mock_variants["sequences"].append(variant)
    
    # Save variants
    with open("EGFR_variants.json", "w") as f:
        json.dump(mock_variants, f, indent=2)
    
    print(f"Generated {len(mock_variants['sequences'])} test variants for EGFR")
    """
}

/*
 * Analyze test CDRs
 */
process analyze_test_cdrs {
    tag "Analyzing test CDRs"
    publishDir "${params.outdir}/analysis", mode: 'copy'

    input:
    path variant_file

    output:
    path "*.json"
    path "*.csv"

    script:
    """
    #!/usr/bin/env python3
    import json
    import pandas as pd
    
    # Load variants
    with open("${variant_file}", "r") as f:
        variants_data = json.load(f)
    
    # Convert to DataFrame
    df = pd.DataFrame(variants_data['sequences'])
    df['target'] = 'EGFR'
    
    # Create mock CDR data
    cdr_data = []
    for _, row in df.iterrows():
        cdr_data.append({
            'heavy_cdr1': 'GYTFTNYWMN',
            'heavy_cdr2': 'YINPYNDGTK',
            'heavy_cdr3': 'ARYYDDHYCLDY',
            'light_cdr1': 'SASSSVSYMH',
            'light_cdr2': 'APSNLAS',
            'light_cdr3': 'QQWSSNPPT',
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
    df_with_cdrs.to_csv("EGFR_variants.csv", index=False)
    
    analysis_result = {
        'target': 'EGFR',
        'total_variants': len(df_with_cdrs),
        'cdr_diversity': diversity_analysis,
        'summary_stats': {
            'avg_score': df_with_cdrs['score'].mean() if 'score' in df_with_cdrs.columns else None,
            'avg_global_score': df_with_cdrs['global_score'].mean() if 'global_score' in df_with_cdrs.columns else None,
            'avg_mutations': df_with_cdrs['mutations'].mean() if 'mutations' in df_with_cdrs.columns else None
        }
    }
    
    with open("EGFR_cdr_analysis.json", "w") as f:
        json.dump(analysis_result, f, indent=2)
    
    print(f"Analyzed CDRs for EGFR: {len(df_with_cdrs)} variants")
    """
}

/*
 * Create test summary
 */
process create_test_summary {
    tag "Creating test summary"
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path analysis_files

    output:
    path "antibody_engineering_test_summary.html"

    script:
    """
    #!/usr/bin/env python3
    import json
    import os
    
    # Load analysis result directly
    with open("EGFR_cdr_analysis.json", "r") as f:
        result = json.load(f)
    
    # Pre-calculate formatted values
    avg_score = f"{result['summary_stats']['avg_score']:.3f}" if result['summary_stats']['avg_score'] is not None else 'N/A'
    avg_global_score = f"{result['summary_stats']['avg_global_score']:.3f}" if result['summary_stats']['avg_global_score'] is not None else 'N/A'
    avg_mutations = f"{result['summary_stats']['avg_mutations']:.1f}" if result['summary_stats']['avg_mutations'] is not None else 'N/A'
    
    # Create summary HTML
    html_content = f'''
    <!DOCTYPE html>
    <html>
    <head>
        <title>BioLM Antibody Engineering Test Summary</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; }}
            .target {{ margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }}
            .stats {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; margin: 10px 0; }}
            .stat {{ background: #f5f5f5; padding: 10px; border-radius: 3px; }}
            table {{ width: 100%; border-collapse: collapse; margin: 10px 0; }}
            th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
            th {{ background-color: #f2f2f2; }}
        </style>
    </head>
    <body>
        <h1>BioLM Antibody Engineering Test Summary</h1>
        <p><strong>Note:</strong> This is a test run with mock data</p>
        
        <div class="target">
            <h2>{result['target']}</h2>
            <div class="stats">
                <div class="stat"><strong>Total Variants:</strong> {result['total_variants']}</div>
                <div class="stat"><strong>Avg Score:</strong> {avg_score}</div>
                <div class="stat"><strong>Avg Global Score:</strong> {avg_global_score}</div>
                <div class="stat"><strong>Avg Mutations:</strong> {avg_mutations}</div>
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
    
    html_content += '''
            </table>
        </div>
    </body>
    </html>
    '''
    
    with open("antibody_engineering_test_summary.html", "w") as f:
        f.write(html_content)
    
    print("Created test summary report")
    """
}

/*
 * Workflow definition
 */
workflow {
    // Create test PDB data
    create_test_pdb()
    
    // Extract test sequences
    extract_test_sequences(create_test_pdb.out)
    
    // Generate test variants
    generate_test_variants(extract_test_sequences.out)
    
    // Analyze test CDRs
    analyze_test_cdrs(generate_test_variants.out)
    
    // Create test summary
    create_test_summary(analyze_test_cdrs.out[0])
}
