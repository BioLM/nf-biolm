#!/usr/bin/env nextflow
/*
 * biosecurity_screen — BioLMTox toxin-like risk classification, plus
 * embeddings for downstream similarity follow-up.
 * Protocol: biolm-protocols/protocols/biosecurity_screen/protocol.yaml
 *
 * Usage:
 *   nextflow run workflows/biosecurity_screen.nf --demo
 */
nextflow.enable.dsl = 2

include { PROTOCOL_RUN } from '../modules/protocol_run.nf'
include { resolveProtocolYaml; resolveDemoInputs; protocolSlug } from '../modules/backend.nf'

process FLAG_HITS {
    tag 'biosecurity_screen'
    publishDir "${params.outdir}/biosecurity_screen", mode: 'copy'

    input:
    path result_json

    output:
    path 'biosecurity_screen.csv'
    path 'flagged.json'

    script:
    """
    summarize_records.py --input "${result_json}" --output-csv biosecurity_screen.csv
    flag_toxin_hits.py --input "${result_json}" --output flagged.json
    """
}

workflow biosecurity_screen {
    take:
    inputs_json

    main:
    protocol_yaml = resolveProtocolYaml('biosecurity_screen')
    slug          = protocolSlug('biosecurity_screen')

    PROTOCOL_RUN('biosecurity_screen', 'biosecurity_screen', slug, protocol_yaml, inputs_json)
    FLAG_HITS(PROTOCOL_RUN.out.result)

    emit:
    result = PROTOCOL_RUN.out.result
}

workflow {
    inputs_json = params.input ? file(params.input) : resolveDemoInputs('biosecurity_screen')
    biosecurity_screen(Channel.fromPath(inputs_json))
}
