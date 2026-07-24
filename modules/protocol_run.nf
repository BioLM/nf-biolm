/*
 * Run a shared biolm-protocols/*.yaml protocol.
 *
 * Execution mode follows params.execution:
 *   'local'  (default) -> `biolm protocol run-local <protocol.yaml>` (honors
 *                          the hub switch since model calls happen in-process)
 *   'hosted'            -> `biolm protocol run <slug> --wait` (orchestration
 *                          stays on the platform; slug must be registered)
 *
 * When params.demo is true, no live BioLM call is made at all: a deterministic
 * local mock (bin/mock_protocol.py) fabricates a plausibly-shaped result so
 * the workflow plumbing can be smoke-tested without a token or network.
 */
include { biolmEnvExports } from './backend.nf'

process PROTOCOL_RUN {
    tag "${workflow_id}"
    publishDir { "${params.outdir}/${workflow_id}" }, mode: 'copy'

    input:
    val workflow_id      // display/tag/publish label — may be round-suffixed (e.g. library_screen_r2)
    val protocol_id      // catalog shape key, e.g. 'library_screen' — used to pick the mock shape
    val protocol_slug
    path protocol_yaml
    path inputs_json

    output:
    path "${workflow_id}.result.json", emit: result

    script:
    def env = biolmEnvExports()
    def outFile = "${workflow_id}.result.json"
    """
    set -euo pipefail
    ${env}

    if [ "${params.demo}" = "true" ]; then
      mock_protocol.py --label "${workflow_id}" --shape "${protocol_id}" \\
        --inputs "${inputs_json}" --output "${outFile}"
    elif [ "${params.execution}" = "hosted" ]; then
      protocol_run.py --mode hosted --slug "${protocol_slug}" \\
        --workflow-id "${workflow_id}" \\
        --inputs "${inputs_json}" --output "${outFile}"
    else
      protocol_run.py --mode local --protocol-yaml "${protocol_yaml}" \\
        --workflow-id "${workflow_id}" \\
        --inputs "${inputs_json}" --output-dir . --output "${outFile}"
    fi
    """
}
