#!/usr/bin/env nextflow
/*
 * intro.nf — thin wrapper kept for backward compatibility.
 *
 * The original biolmai-based structure-prediction workflow has moved to
 * workflows/structure_predict.nf (biolm-sdk, backend switch, demo mock).
 * Prefer calling that directly:
 *
 *   nextflow run workflows/structure_predict.nf --demo
 */
nextflow.enable.dsl = 2

include { structure_predict } from './workflows/structure_predict.nf'

workflow {
    def fasta_path = params.input ? file(params.input) : file('data/demo/sequences.fasta')
    structure_predict(Channel.fromPath(fasta_path))
}
