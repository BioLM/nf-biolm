#!/usr/bin/env nextflow
/*
 * dms_landscape — in silico deep mutational scan with ESM-1v.
 * Protocol: biolm-protocols/protocols/dms_landscape/protocol.yaml
 *
 * Usage:
 *   nextflow run workflows/dms_landscape.nf --demo
 */
nextflow.enable.dsl = 2

include { PROTOCOL_RUN } from '../modules/protocol_run.nf'
include { resolveProtocolYaml; resolveDemoInputs; protocolSlug } from '../modules/backend.nf'

process SUMMARIZE {
    tag 'dms_landscape'
    publishDir "${params.outdir}/dms_landscape", mode: 'copy'

    input:
    path result_json

    output:
    path 'dms_landscape.csv'

    script:
    """
    summarize_records.py --input "${result_json}" --output-csv dms_landscape.csv
    """
}

workflow dms_landscape {
    take:
    inputs_json

    main:
    protocol_yaml = resolveProtocolYaml('dms_landscape')
    slug          = protocolSlug('dms_landscape')

    PROTOCOL_RUN('dms_landscape', 'dms_landscape', slug, protocol_yaml, inputs_json)
    SUMMARIZE(PROTOCOL_RUN.out.result)

    emit:
    result  = PROTOCOL_RUN.out.result
    csv     = SUMMARIZE.out
}

workflow {
    inputs_json = params.input ? file(params.input) : resolveDemoInputs('dms_landscape')
    dms_landscape(Channel.fromPath(inputs_json))
}
