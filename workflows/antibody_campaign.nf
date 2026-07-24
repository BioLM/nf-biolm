#!/usr/bin/env nextflow
/*
 * antibody_campaign — AntiFold variant generation from a scaffold PDB,
 * followed by ESM2 embeddings of the designed sequences.
 * Protocol: biolm-protocols/protocols/antibody_campaign/protocol.yaml
 *
 * Replaces the legacy antibody_engineering.nf (biolmai/AntiFold-only, no
 * embedding step, no backend switch). See README for the migration note.
 *
 * Usage:
 *   nextflow run workflows/antibody_campaign.nf --demo
 */
nextflow.enable.dsl = 2

include { PROTOCOL_RUN } from '../modules/protocol_run.nf'
include { resolveProtocolYaml; resolveDemoInputs; protocolSlug } from '../modules/backend.nf'

process SUMMARIZE {
    tag 'antibody_campaign'
    publishDir "${params.outdir}/antibody_campaign", mode: 'copy'

    input:
    path result_json

    output:
    path 'antibody_campaign.csv'

    script:
    """
    summarize_records.py --input "${result_json}" --output-csv antibody_campaign.csv
    """
}

workflow antibody_campaign {
    take:
    inputs_json

    main:
    protocol_yaml = resolveProtocolYaml('antibody_campaign')
    slug          = protocolSlug('antibody_campaign')

    PROTOCOL_RUN('antibody_campaign', 'antibody_campaign', slug, protocol_yaml, inputs_json)
    SUMMARIZE(PROTOCOL_RUN.out.result)

    emit:
    result = PROTOCOL_RUN.out.result
    csv    = SUMMARIZE.out
}

workflow {
    inputs_json = params.input ? file(params.input) : resolveDemoInputs('antibody_campaign')
    antibody_campaign(Channel.fromPath(inputs_json))
}
