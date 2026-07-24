#!/usr/bin/env nextflow
/*
 * antibody_engineering.nf — thin wrapper kept for backward compatibility.
 *
 * The original biolmai-based AntiFold-only workflow (PDB download, no
 * embeddings, no backend switch, no demo mock) has been replaced by the
 * shared antibody_campaign protocol (AntiFold generate + ESM2 embed).
 * Prefer calling that directly:
 *
 *   nextflow run workflows/antibody_campaign.nf --demo
 *
 * `antibody_engineering_test.nf`'s mock-data pattern is now built into
 * workflows/antibody_campaign.nf itself via `--demo` (bin/mock_protocol.py),
 * so a separate test workflow file is no longer needed.
 */
nextflow.enable.dsl = 2

include { antibody_campaign } from './workflows/antibody_campaign.nf'
include { resolveDemoInputs }  from './modules/backend.nf'

workflow {
    inputs_json = params.input ? file(params.input) : resolveDemoInputs('antibody_campaign')
    antibody_campaign(Channel.fromPath(inputs_json))
}
