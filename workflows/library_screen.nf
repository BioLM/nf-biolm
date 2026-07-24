#!/usr/bin/env nextflow
/*
 * library_screen — fold-first multi-property screen: ESMFold confidence gate
 * plus thermal stability scoring, then filter to top candidates.
 * Protocol: biolm-protocols/protocols/library_screen/protocol.yaml
 *
 * Usage:
 *   nextflow run workflows/library_screen.nf --demo
 *   nextflow run workflows/library_screen.nf --demo --min_plddt 60 --top_n 5
 */
nextflow.enable.dsl = 2

include { PROTOCOL_RUN } from '../modules/protocol_run.nf'
include { resolveProtocolYaml; resolveDemoInputs; protocolSlug } from '../modules/backend.nf'

process FILTER_CANDIDATES {
    tag 'library_screen'
    publishDir "${params.outdir}/library_screen", mode: 'copy'

    input:
    path result_json

    output:
    path 'library_screen.filtered.json', emit: filtered
    path 'library_screen.csv', emit: csv

    script:
    """
    pick_top_records.py --input "${result_json}" --output library_screen.filtered.json \\
      --sort-by tm --filter-field mean_plddt --min-value ${params.min_plddt} --top ${params.top_n} \\
      || cp "${result_json}" library_screen.filtered.json
    summarize_records.py --input library_screen.filtered.json --output-csv library_screen.csv
    """
}

workflow library_screen {
    take:
    inputs_json

    main:
    protocol_yaml = resolveProtocolYaml('library_screen')
    slug          = protocolSlug('library_screen')

    PROTOCOL_RUN('library_screen', 'library_screen', slug, protocol_yaml, inputs_json)
    FILTER_CANDIDATES(PROTOCOL_RUN.out.result)

    emit:
    result   = PROTOCOL_RUN.out.result
    filtered = FILTER_CANDIDATES.out.filtered
    csv      = FILTER_CANDIDATES.out.csv
}

workflow {
    inputs_json = params.input ? file(params.input) : resolveDemoInputs('library_screen')
    library_screen(Channel.fromPath(inputs_json))
}
