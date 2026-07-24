#!/usr/bin/env nextflow
/*
 * embed_cluster — ESM2 embeddings + a stability-proxy score for library
 * diversification. Protocol: biolm-protocols/protocols/embed_cluster/protocol.yaml
 *
 * Usage:
 *   nextflow run workflows/embed_cluster.nf --demo
 */
nextflow.enable.dsl = 2

include { PROTOCOL_RUN } from '../modules/protocol_run.nf'
include { resolveProtocolYaml; resolveDemoInputs; protocolSlug } from '../modules/backend.nf'

process BUCKET_BY_SCORE {
    tag 'embed_cluster'
    publishDir "${params.outdir}/embed_cluster", mode: 'copy'

    input:
    path result_json

    output:
    path 'embed_cluster.buckets.csv'

    script:
    """
    bucket_by_score.py --input "${result_json}" --by tm --output-csv embed_cluster.buckets.csv
    """
}

workflow embed_cluster {
    take:
    inputs_json

    main:
    protocol_yaml = resolveProtocolYaml('embed_cluster')
    slug          = protocolSlug('embed_cluster')

    PROTOCOL_RUN('embed_cluster', 'embed_cluster', slug, protocol_yaml, inputs_json)
    BUCKET_BY_SCORE(PROTOCOL_RUN.out.result)

    emit:
    result  = PROTOCOL_RUN.out.result
    buckets = BUCKET_BY_SCORE.out
}

workflow {
    inputs_json = params.input ? file(params.input) : resolveDemoInputs('embed_cluster')
    embed_cluster(Channel.fromPath(inputs_json))
}
