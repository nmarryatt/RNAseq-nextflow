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

// MultiQC: aggregate all FASTQC reports together
process multiqc{
    publishDir "${params.outdir}", mode: 'copy'
    
    input:
    path('*')  // Takes all FastQC outputs
    
    output:
    path "multiqc_report.html"
    path "multiqc_data"
    
    script:
    """
    multiqc .
    """
}


// Workflow

workflow {
    reads_ch = Channel.fromPath(params.reads)
    //reads_ch.view { "Found file: $it" } 
    fastqc_out = fastqc(reads_ch)
    multiqc(fastqc_out.collect())
}