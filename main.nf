#!/usr/bin/env nextflow


// Parameters
params.reads = '/Users/nataliemarryatt/RNAseq-nextflow/test-datasets/testdata/*_subsamp.fastq.gz'
params.outdir = '/Users/nataliemarryatt/RNAseq-nextflow/results'



// Process: print out fastq files
process check_files {

    publishDir params.outdir, mode: 'copy'

    input:
        path fastq

    output:
        path "*.txt"

    script:
    """
    echo "Found FASTQ file: $fastq" > ${fastq.simpleName}_info.txt
    """
}


// Fastqc
process fastqc {
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
        path reads

    output:
        path "*_fastqc.{html,zip}"
    
    script:
    """
    fastqc -q ${reads}
    """

}

// Workflow

workflow {
    reads_ch = Channel.fromPath(params.reads)
    reads_ch.view()
    reads_ch.view { "Found file: $it" } 
    fastqc(reads_ch)
    
}