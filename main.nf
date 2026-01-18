#!/usr/bin/env nextflow

// Parameters
params.reads = '/Users/nataliemarryatt/RNAseq-nextflow/test-datasets/testdata/*_subsamp.fastq.gz'
params.outdir = '/Users/nataliemarryatt/RNAseq-nextflow/results'
params.salmon_index = "/Users/nataliemarryatt/RNAseq-nextflow/test-datasets/reference/salmon"
params.transcriptome_fasta= '/Users/nataliemarryatt/RNAseq-nextflow/test-datasets/reference/transcriptome.fasta'
params.genome_fasta = "/Users/nataliemarryatt/RNAseq-nextflow/test-datasets/reference/genome.fa"  
params.gff = "/Users/nataliemarryatt/RNAseq-nextflow/test-datasets/reference/genes.gff"  


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
        path "*_fastqc.{html,zip}", emit: reports
    
    script:
    """
    fastqc -q ${reads}
    """

}

// Create salmon index
process salmon_index {

    publishDir "${params.outdir}/salmon_index", mode: 'copy'
    cpus 4
    memory '8 GB'
    
    input:
    path transcriptome_fasta
    
    output:
    path "salmon_index"
    
    script:
    """
    salmon index \
        -t ${transcriptome_fasta} \
        -i salmon_index \
        -k 31 \
        -p ${task.cpus}
    """
}


// Salmon quantification
process salmon_quant {
    tag "$reads.simpleName"
    publishDir "${params.outdir}/salmon", mode: 'copy'
    
    input:
    path reads
    path salmon_index
    
    output:
    path "${reads.simpleName}_quant", emit: quant
    path "${reads.simpleName}_quant/logs", emit: logs
    
    script:
    """
    salmon quant -i ${salmon_index} \
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
    path('data_fastqc/*')
    path('data_salmon/*')
    path('data_star/*')
    
    
    output:
    path "multiqc_report.html"
    path "multiqc_data"
    
    script:
    """
    multiqc .
    """
}


process star_index {
    publishDir "${params.outdir}/star_index", mode: 'copy'
    cpus 4
    memory '8 GB'
    
    input:
    path genome_fasta
    path gff
    
    output:
    path "star_index"
    
    script:
    """
    mkdir star_index
    STAR --runMode genomeGenerate \
         --genomeDir star_index \
         --genomeFastaFiles ${genome_fasta} \
         --sjdbGTFfile ${gff} \
         --sjdbGTFtagExonParentTranscript Parent \
         --genomeSAindexNbases 7 \
         --runThreadN ${task.cpus}
    """
}


process star_align {
    tag "$reads.simpleName"
    publishDir "${params.outdir}/star", mode: 'copy'
    cpus 4
    memory '8 GB'
    
    input:
    path star_index
    path reads
    
    output:
    path "*Aligned.sortedByCoord.out.bam", emit: bam
    path "*Log.final.out", emit: logs
    path "*ReadsPerGene.out.tab", emit: counts
    
    script:
    """
    STAR --runThreadN ${task.cpus} \
         --genomeDir ${star_index} \
         --readFilesIn ${reads} \
         --readFilesCommand zcat \
         --outSAMtype BAM SortedByCoordinate \
         --quantMode GeneCounts \
         --outFileNamePrefix ${reads.simpleName}_ \
         --limitBAMsortRAM 4000000000
    """
}

// Workflow
workflow {
    reads_ch = Channel.fromPath(params.reads, checkIfExists: true)
    
    // Run FastQC
    fastqc_out = fastqc(reads_ch)
    
 
    // Salmon index - build or use existing
    if (params.build_salmon_index) {
        salmon_index = salmon_index(params.transcriptome_fasta)
    } else {
        salmon_index = Channel.fromPath(params.salmon_index, type: 'dir')
    }

    // Run Salmon
    salmon_out = salmon_quant(reads_ch, salmon_index)
    
    // Create STAR index
    star_index = star_index(params.genome_fasta, params.gff)

    // Run STAR
    star_out = star_align( star_index, reads_ch)

    
    // Aggregate all for MultiQC
    multiqc(
        fastqc_out.reports.collect(),
        salmon_out.quant.collect(),
        star_out.logs.collect()
    )
}


params.build_salmon_index = true  
