#!/usr/bin/env nextflow
/*
 * sat_mut_stability — stability scoring for a (pre-enumerated or
 * framework-enumerated) single-mutant library.
 * Protocol: biolm-protocols/protocols/sat_mut_stability/protocol.yaml
 *
 * Usage:
 *   nextflow run workflows/sat_mut_stability.nf --demo
 *   # Or auto-enumerate a saturation library from a wild-type sequence:
 *   nextflow run workflows/sat_mut_stability.nf --demo \
 *     --wildtype MKTAYIAKQRQISFVKSHFSRQLEERLGLIEVQ --max_variants 40
 */
nextflow.enable.dsl = 2

include { PROTOCOL_RUN } from '../modules/protocol_run.nf'
include { resolveProtocolYaml; resolveDemoInputs; protocolSlug } from '../modules/backend.nf'

process ENUMERATE_LIBRARY {
    tag 'sat_mut_stability'

    output:
    path 'sat_mut_stability.inputs.json'

    script:
    """
    enumerate_point_mutants.py --wildtype "${params.wildtype}" \\
      --max-variants ${params.max_variants} --output sat_mut_stability.inputs.json
    """
}

process SUMMARIZE {
    tag 'sat_mut_stability'
    publishDir "${params.outdir}/sat_mut_stability", mode: 'copy'

    input:
    path result_json

    output:
    path 'sat_mut_stability.csv'

    script:
    """
    summarize_records.py --input "${result_json}" --output-csv sat_mut_stability.csv
    """
}

workflow sat_mut_stability {
    take:
    inputs_json

    main:
    protocol_yaml = resolveProtocolYaml('sat_mut_stability')
    slug          = protocolSlug('sat_mut_stability')

    PROTOCOL_RUN('sat_mut_stability', 'sat_mut_stability', slug, protocol_yaml, inputs_json)
    SUMMARIZE(PROTOCOL_RUN.out.result)

    emit:
    result = PROTOCOL_RUN.out.result
    csv    = SUMMARIZE.out
}

workflow {
    if (params.wildtype) {
        ENUMERATE_LIBRARY()
        inputs_ch = ENUMERATE_LIBRARY.out
    } else {
        inputs_ch = Channel.fromPath(params.input ? file(params.input) : resolveDemoInputs('sat_mut_stability'))
    }
    sat_mut_stability(inputs_ch)
}
