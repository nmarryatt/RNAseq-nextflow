#!/usr/bin/env nextflow

// Parameters
params.reads = '/Users/nataliemarryatt/RNAseq-nextflow/test-datasets/testdata/*_subsamp.fastq.gz'
params.outdir = '/Users/nataliemarryatt/RNAseq-nextflow/results'
params.salmon_index = "/Users/nataliemarryatt/RNAseq-nextflow/test-datasets/reference/salmon"


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

// Salmon quantification
process salmon_quant {
    tag "$reads.simpleName"
    publishDir "${params.outdir}/salmon", mode: 'copy'
    
    input:
    path reads
    
    output:
    path "${reads.simpleName}_quant", emit: quant
    path "${reads.simpleName}_quant/logs", emit: logs
    
    script:
    """
    salmon quant -i ${params.salmon_index} \
        -l A \
        -r ${reads} \
        -o ${reads.simpleName}_quant \
        --validateMappings
    """
}


// MultiQC: aggregate all FASTQC reports together
process multiqc{
    publishDir "${params.outdir}", mode: 'copy'
    
    input:
    path('*', stageAs: 'input?/*') // Takes all FastQC outputs
    
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
    salmon_out = salmon_quant(reads_ch)

    all_outputs = fastqc_out
        .mix(salmon_out)
        .flatten()
        .collect()


    multiqc(all_outputs)
}