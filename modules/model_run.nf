/*
 * Run a single BioLM model action (e.g. esmfold predict) on one sequence.
 *
 * Honors params.demo (cheap local mock, no token/network needed) and the
 * shared backend switch (params.backend / params.hub_url) via backend.nf.
 */
include { biolmEnvExports } from './backend.nf'

process MODEL_RUN {
    tag "${seq_id}:${model}:${action}"
    maxForks params.max_forks ?: 4
    publishDir "${params.outdir}/json", mode: 'copy', pattern: "*.json"
    publishDir "${params.outdir}/pdbs", mode: 'copy', pattern: "*.pdb"

    input:
    tuple val(seq_id), path(seq_fasta)
    val model
    val action

    output:
    tuple val(seq_id), path("${seq_id}.${model}.json"), emit: json
    path "${seq_id}.${model}.pdb", optional: true, emit: pdb

    script:
    def env = biolmEnvExports()
    """
    set -euo pipefail
    ${env}

    if [ "${params.demo}" = "true" ]; then
      mock_model.py --model "${model}" --action "${action}" \\
        --input "${seq_fasta}" --output "${seq_id}.${model}.json"
    else
      model_run.py "${model}" "${action}" \\
        --input "${seq_fasta}" --input-format fasta \\
        --output "${seq_id}.${model}.json"
    fi

    extract_pdb.py --input "${seq_id}.${model}.json" --output "${seq_id}.${model}.pdb" || true
    """
}
