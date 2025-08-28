#!/usr/bin/env nextflow

/*
 * BioLM SDK Introduction Workflow
 * 
 * A unified workflow for protein structure prediction using BioLM SDK.
 * Can run in demo mode (single hardcoded sequence) or process FASTA files.
 */

nextflow.enable.dsl = 2

// Parameters
params.token = params.token ?: System.getenv('BIOLMAI_TOKEN') ?: ''
params.input = params.input ?: ''
params.demo = params.demo ?: false
params.outdir = params.outdir ?: 'results'

/*
 * Demo mode: Create a simple FASTA with demo sequence
 */
process create_demo_fasta {
    output:
    path "demo_sequence.fasta"

    script:
    """
    cat > demo_sequence.fasta <<'EOF'
    >DEMO
    MKTVRQERLKSIVRILERSKEPVSGAQLAEELSVSRQVIVQDIAYLRSLGYNIVATPRGYVLAGG
    EOF
    """
}

/*
 * Default mode: Create GFP FASTA
 */
process create_default_fasta {
    output:
    path "input_sequences.fasta"

    script:
    """
    cat > input_sequences.fasta <<'EOF'
    >GFP
    MSKGEELFTGVVPILVELDGDVNGHKFSVSGEGEGDATYGKLTLKFICTTGKLPVPWPTL
    VTTFSYGVQCFSRYPDHMKQHDFFKSAMPEGYVQERTIFFKDDGNYKTRAEVKFEGDTLV
    NRIELKGIDFKEDGNILGHKLEYNYNSHNVYIMADKQKNGIKVNFKIRHNIEDGSVQLAD
    HYQQNTPIGDGPVLLPDNHYLSTQSALSKDPNEKRDHMVLLEFVTAAGITHGMDELYK
    EOF
    """
}

/*
 * Split FASTA into one file per sequence
 */
process split_fasta {
    input:
    path fasta

    output:
    path "split/*.fa"

    script:
    """
    mkdir -p split
    awk '/^>/{close(out); out="split/" substr(\$0,2) ".fa"} {print > out}' "${fasta}"
    """
}

/*
 * Predict structure with BioLM
 */
process predict_with_biolm {
    tag "${seq_id}"
    publishDir "${params.outdir}/json", mode: 'copy'

    input:
    tuple val(seq_id), path(seq_file)

    output:
    path "${seq_id}.json"

    script:
    """
    #!/usr/bin/env python3
    import json
    import os
    from biolmai import BioLM

    # Read the FASTA file
    with open("${seq_file}", "r") as f:
        lines = f.readlines()

    # Extract sequence (skip header line starting with >)
    sequence = ""
    for line in lines:
        if not line.startswith(">"):
            sequence += line.strip()

    # Run BioLM prediction
    result = BioLM(
        entity="esmfold",
        action="predict",
        items=[{"sequence": sequence}],
        api_key="${params.token}"
    )

    # Save JSON result
    with open("${seq_id}.json", "w") as f:
        json.dump(result, f, indent=2)

    print(f"Prediction complete for ${seq_id}: {sequence[:20]}...")
    """
}

/*
 * Extract PDB structure from BioLM JSON results
 */
process extract_pdb {
    tag "${seq_id}"
    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(seq_id), path(json_file)

    output:
    path "${seq_id}.pdb"

    script:
    """
    #!/usr/bin/env python3
    import json
    import os

    # Read the JSON file
    with open("${json_file}", "r") as f:
        data = json.load(f)

    # Extract and save PDB structure
    if 'pdb' in data:
        with open("${seq_id}.pdb", "w") as f:
            f.write(data['pdb'])
        print(f"PDB structure extracted to ${seq_id}.pdb")
    else:
        print(f"Warning: No PDB data found in result for ${seq_id}")
        # Create empty PDB file to satisfy output requirement
        with open("${seq_id}.pdb", "w") as f:
            f.write("# No PDB data available\\n")

    print(f"PDB extraction complete for ${seq_id}")
    """
}

/*
 * Workflow definition
 */
workflow {
    // Determine input source based on parameters
    if (params.demo) {
        // Demo mode: use hardcoded sequence
        split_fasta(create_demo_fasta())
    } else if (params.input) {
        // User-provided FASTA file
        split_fasta(Channel.fromPath(params.input))
    } else {
        // Default mode: use GFP sequence
        split_fasta(create_default_fasta())
    }
    
    def per_seq_fastas = split_fasta.out
    def seq_pairs = per_seq_fastas.map { f -> tuple(f.baseName, f) }

    // Run BioLM predictions
    def prediction_results = predict_with_biolm(seq_pairs)
    
    // Map the results to include sequence ID for PDB extraction
    def pdb_inputs = prediction_results.map { json_file -> 
        def seq_id = json_file.baseName
        tuple(seq_id, json_file)
    }
    
    // Extract PDB files from JSON results
    extract_pdb(pdb_inputs)
}
