/*
 * Shared backend/catalog helpers.
 *
 * Every process that calls the `biolm` CLI sources its environment from
 * `biolmEnvExports()` so `--backend`, `--hub_url`, and the token are honored
 * consistently in one place instead of being re-implemented per workflow.
 *
 * Protocol YAML lookups use the in-repo `catalog.json` (see params.protocols_root).
 */

// Shell snippet (bash) that configures BIOLM_TOKEN / BIOLM_BASE_API_URL
// for the active backend. Safe to prepend to any process script.
def biolmEnvExports() {
    def lines = []
    def backend = (params.backend ?: 'platform').toString().toLowerCase()
    if (backend == 'hub') {
        def hubUrl = params.hub_url ?: 'http://127.0.0.1:8000'
        lines << "export BIOLM_BASE_API_URL=\"${hubUrl}\""
    } else {
        lines << "unset BIOLM_BASE_API_URL 2>/dev/null || true"
    }
    def token = params.token ?: ''
    if (token) {
        lines << "export BIOLM_TOKEN=\"${token}\""
    }
    return lines.join('\n')
}

// Loads catalog.json from the protocol catalog root (default: repo root).
def loadCatalog() {
    def root = params.protocols_root ?: '.'
    def catalogFile = file("${root}/catalog.json")
    if (!catalogFile.exists()) {
        throw new RuntimeException(
            "Cannot find catalog.json at '${catalogFile}'. " +
            "Set --protocols_root or BIOLM_PROTOCOLS_ROOT (default: '.' = this repo)."
        )
    }
    return new groovy.json.JsonSlurper().parse(catalogFile)
}

def catalogEntry(String workflowId) {
    def catalog = loadCatalog()
    def entry = catalog.protocols[workflowId]
    if (!entry) {
        throw new RuntimeException("Workflow '${workflowId}' not found in catalog.json protocols{}.")
    }
    return entry
}

// Resolved path to protocols/<id>/protocol.yaml under protocols_root.
def resolveProtocolYaml(String workflowId) {
    def root = params.protocols_root ?: '.'
    def entry = catalogEntry(workflowId)
    return file("${root}/${entry.path}")
}

// Resolved path to fixtures/demo/<id>.inputs.json under protocols_root.
def resolveDemoInputs(String workflowId) {
    def root = params.protocols_root ?: '.'
    def entry = catalogEntry(workflowId)
    return file("${root}/${entry.demo_inputs}")
}

// Registered protocol name/slug (e.g. "biolm/embed-cluster-v1") used for
// hosted `biolm protocol run <slug>` execution.
def protocolSlug(String workflowId) {
    return catalogEntry(workflowId).name
}
