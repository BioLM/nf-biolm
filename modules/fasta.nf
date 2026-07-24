/*
 * Split a multi-FASTA into one file per record, tagged by record id.
 */
process SPLIT_FASTA {
    tag "${fasta.baseName}"

    input:
    path fasta

    output:
    path "split/*.fa"

    script:
    """
    mkdir -p split
    awk '/^>/{close(out); id=substr(\$0,2); sub(/[ \\t].*\$/, "", id); out="split/" id ".fa"} out{print > out}' "${fasta}"
    """
}
