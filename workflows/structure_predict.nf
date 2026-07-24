#!/usr/bin/env nextflow
/*
 * structure_predict — protein structure prediction via BioLM.
 *
 * Model: esmfold (default) or boltz-2 (--boltz2 / --structure_model boltz-2)
 * Catalog: see biolm-protocols/CATALOG.md ("structure_predict")
 *
 * Usage:
 *   nextflow run workflows/structure_predict.nf --demo
 *   nextflow run workflows/structure_predict.nf --input my_seqs.fasta
 *   nextflow run workflows/structure_predict.nf --boltz2 --demo
 */
nextflow.enable.dsl = 2

include { SPLIT_FASTA } from '../modules/fasta.nf'
include { MODEL_RUN }   from '../modules/model_run.nf'

// params.structure_model / params.boltz2 are declared with defaults in nextflow.config

workflow structure_predict {
    take:
    fasta

    main:
    def model = params.boltz2 ? 'boltz-2' : (params.structure_model ?: 'esmfold')

    SPLIT_FASTA(fasta)
    seq_ch = SPLIT_FASTA.out
        .flatten()
        .map { f -> tuple(f.baseName, f) }

    MODEL_RUN(seq_ch, model, 'predict')

    emit:
    json = MODEL_RUN.out.json
    pdb  = MODEL_RUN.out.pdb
}

workflow {
    def fasta_path = params.input ? file(params.input) : file('data/demo/sequences.fasta')
    structure_predict(Channel.fromPath(fasta_path))

    structure_predict.out.pdb
        .collect()
        .subscribe { pdbs -> log.info "structure_predict: wrote ${pdbs.size()} PDB file(s) to ${params.outdir}/pdbs" }
}
