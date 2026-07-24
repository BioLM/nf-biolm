#!/usr/bin/env nextflow
/*
 * inverse_fold — ProteinMPNN structure-conditioned sequence design from a
 * backbone PDB.
 * Protocol: biolm-protocols/protocols/inverse_fold/protocol.yaml
 *
 * Usage:
 *   nextflow run workflows/inverse_fold.nf --demo
 */
nextflow.enable.dsl = 2

include { PROTOCOL_RUN } from '../modules/protocol_run.nf'
include { resolveProtocolYaml; resolveDemoInputs; protocolSlug } from '../modules/backend.nf'

process TO_FASTA {
    tag 'inverse_fold'
    publishDir "${params.outdir}/inverse_fold", mode: 'copy'

    input:
    path result_json

    output:
    path 'designed_sequences.fasta'
    path 'inverse_fold.csv'

    script:
    """
    summarize_records.py --input "${result_json}" --output-csv inverse_fold.csv
    records_to_fasta.py --input "${result_json}" --prefix design --output designed_sequences.fasta
    """
}

workflow inverse_fold {
    take:
    inputs_json

    main:
    protocol_yaml = resolveProtocolYaml('inverse_fold')
    slug          = protocolSlug('inverse_fold')

    PROTOCOL_RUN('inverse_fold', 'inverse_fold', slug, protocol_yaml, inputs_json)
    TO_FASTA(PROTOCOL_RUN.out.result)

    emit:
    result = PROTOCOL_RUN.out.result
}

workflow {
    inputs_json = params.input ? file(params.input) : resolveDemoInputs('inverse_fold')
    inverse_fold(Channel.fromPath(inputs_json))
}
