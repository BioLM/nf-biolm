#!/usr/bin/env nextflow
/*
 * parallel_fold_farm — scatter a FASTA of many sequences into one esmfold
 * (or boltz-2) prediction per sequence, run with bounded parallelism, and
 * gather a pLDDT summary. (Extra #6; Model scatter, no protocol YAML.)
 *
 * Usage:
 *   nextflow run workflows/parallel_fold_farm.nf --demo
 *   nextflow run workflows/parallel_fold_farm.nf --input many_seqs.fasta --max_forks 8
 */
nextflow.enable.dsl = 2

include { SPLIT_FASTA } from '../modules/fasta.nf'
include { MODEL_RUN }   from '../modules/model_run.nf'

process GATHER_PLDDT {
    tag 'parallel_fold_farm'
    publishDir "${params.outdir}/parallel_fold_farm", mode: 'copy'

    input:
    path json_files

    output:
    path 'fold_farm_summary.csv'

    script:
    """
    fold_farm_summary.py --output-csv fold_farm_summary.csv ${json_files}
    """
}

workflow parallel_fold_farm {
    take:
    fasta

    main:
    def model = params.boltz2 ? 'boltz-2' : (params.structure_model ?: 'esmfold')

    SPLIT_FASTA(fasta)
    seq_ch = SPLIT_FASTA.out
        .flatten()
        .map { f -> tuple(f.baseName, f) }

    MODEL_RUN(seq_ch, model, 'predict')
    GATHER_PLDDT(MODEL_RUN.out.json.map { id, f -> f }.collect())

    emit:
    json    = MODEL_RUN.out.json
    pdb     = MODEL_RUN.out.pdb
    summary = GATHER_PLDDT.out
}

workflow {
    def fasta_path = params.input ? file(params.input) : file('data/demo/sequences.fasta')
    parallel_fold_farm(Channel.fromPath(fasta_path))
}
