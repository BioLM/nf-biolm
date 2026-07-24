/*
 * Advance one trickle_screen round: pick survivors from the previous round's
 * library_screen result and mutate them into a fresh candidate pool.
 *
 * Lives in its own module (rather than inline in workflows/trickle_screen.nf)
 * so it can be imported multiple times under aliases — Nextflow forbids
 * invoking the same process more than once in one workflow, and
 * trickle_screen's round count is a compile-time-unrolled chain (see
 * workflows/trickle_screen.nf for why).
 */
process ADVANCE_ROUND {
    tag "round ${round}"

    input:
    path previous_result
    val round

    output:
    path "trickle_round${round + 1}.inputs.json"

    script:
    """
    trickle_advance.py --previous-result "${previous_result}" --round ${round} \\
      --survivors ${params.survivors} --new-per-round ${params.new_per_round} \\
      --output "trickle_round${round + 1}.inputs.json"
    """
}
