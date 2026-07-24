#!/usr/bin/env nextflow
/*
 * trickle_screen — iterative library_screen: each round screens the current
 * sequence pool, keeps the top survivors by Tm, mutates them into a handful
 * of new candidates, and feeds that pool into the next round.
 * (Extra #10; re-runs the shared library_screen protocol across rounds —
 * no separate YAML of its own.)
 *
 * Implementation note: Nextflow forbids invoking the same process twice in
 * one workflow, so a real `for` loop over rounds isn't possible here. This
 * unrolls up to MAX_ROUNDS aliased instances of PROTOCOL_RUN / ADVANCE_ROUND
 * instead and only *runs* the first `params.rounds` of them.
 *
 * Usage:
 *   nextflow run workflows/trickle_screen.nf --demo
 *   nextflow run workflows/trickle_screen.nf --demo --rounds 4 --survivors 3 --new_per_round 3
 */
nextflow.enable.dsl = 2

include { PROTOCOL_RUN as PR1 } from '../modules/protocol_run.nf'
include { PROTOCOL_RUN as PR2 } from '../modules/protocol_run.nf'
include { PROTOCOL_RUN as PR3 } from '../modules/protocol_run.nf'
include { PROTOCOL_RUN as PR4 } from '../modules/protocol_run.nf'
include { PROTOCOL_RUN as PR5 } from '../modules/protocol_run.nf'
include { PROTOCOL_RUN as PR6 } from '../modules/protocol_run.nf'
include { ADVANCE_ROUND as AR1 } from '../modules/trickle_advance.nf'
include { ADVANCE_ROUND as AR2 } from '../modules/trickle_advance.nf'
include { ADVANCE_ROUND as AR3 } from '../modules/trickle_advance.nf'
include { ADVANCE_ROUND as AR4 } from '../modules/trickle_advance.nf'
include { ADVANCE_ROUND as AR5 } from '../modules/trickle_advance.nf'
include { resolveProtocolYaml; resolveDemoInputs; protocolSlug } from '../modules/backend.nf'

def maxRounds() { return 6 }

process COMBINE_ROUNDS {
    tag 'trickle_screen'
    publishDir "${params.outdir}/trickle_screen", mode: 'copy'

    input:
    path result_jsons

    output:
    path 'trickle_screen.csv'

    script:
    """
    combine_trickle_rounds.py --output-csv trickle_screen.csv ${result_jsons}
    """
}

workflow trickle_screen {
    take:
    seed_inputs_json

    main:
    protocol_yaml = resolveProtocolYaml('library_screen')
    slug          = protocolSlug('library_screen')

    def requested = (params.rounds ?: 3) as int
    def n_rounds  = Math.min(Math.max(requested, 1), maxRounds())
    if (requested > maxRounds()) {
        log.warn "trickle_screen: --rounds ${requested} exceeds the supported max (${maxRounds()}); using ${maxRounds()}"
    }

    def results = []

    PR1("library_screen_r1", 'library_screen', slug, protocol_yaml, seed_inputs_json)
    results << PR1.out.result

    if (n_rounds >= 2) {
        AR1(PR1.out.result, 1)
        PR2("library_screen_r2", 'library_screen', slug, protocol_yaml, AR1.out)
        results << PR2.out.result
    }
    if (n_rounds >= 3) {
        AR2(PR2.out.result, 2)
        PR3("library_screen_r3", 'library_screen', slug, protocol_yaml, AR2.out)
        results << PR3.out.result
    }
    if (n_rounds >= 4) {
        AR3(PR3.out.result, 3)
        PR4("library_screen_r4", 'library_screen', slug, protocol_yaml, AR3.out)
        results << PR4.out.result
    }
    if (n_rounds >= 5) {
        AR4(PR4.out.result, 4)
        PR5("library_screen_r5", 'library_screen', slug, protocol_yaml, AR4.out)
        results << PR5.out.result
    }
    if (n_rounds >= 6) {
        AR5(PR5.out.result, 5)
        PR6("library_screen_r6", 'library_screen', slug, protocol_yaml, AR5.out)
        results << PR6.out.result
    }

    merged_results = results.inject { a, b -> a.mix(b) }
    COMBINE_ROUNDS(merged_results.collect())

    emit:
    summary = COMBINE_ROUNDS.out
}

workflow {
    seed = params.input ? file(params.input) : resolveDemoInputs('library_screen')
    trickle_screen(Channel.fromPath(seed))
}
