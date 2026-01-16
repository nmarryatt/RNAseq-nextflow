# RNA-Seq Nextflow Pipeline
A simple, reproducible RNA-seq workflow implemented in Nextflow (DSL2) with Conda-based tool management.
This project is designed as a learning and portfolio pipeline demonstrating best practices in workflow development for bioinformatics.

## Overview
This pipeline performs basic RNA-seq processing on FASTQ files, including quality control, transcript quantification, and QC aggregation.

**Current steps:**
1. **Input validation:** confirms FASTQ files are detected
2. **Quality control:** runs FastQC on each input FASTQ file
3. **Transcript quantification:** runs Salmon in alignment-free mode using a pre-built transcriptome index
4. **QC aggregation:** aggregates FastQC outputs into a single MultiQC report

## Requirements
Nextflow ≥ 25, Java 17, Conda (Miniconda or Anaconda recommended).
All bioinformatics tools are installed automatically using Conda environments defined in nextflow.config.

## Usage
Run the pipeline from the project directory:
```bash
nextflow run main.nf
```

Parameters are defined in nextflow.config and can be overridden at runtime:
--reads	(path pattern to input FASTQ files). 
--outdir (output directory for pipeline results).  
--salmon_index (path to a pre-built Salmon transcriptome index).  

This pipeline uses Conda to manage tool dependencies. No manual installation of tools required


## Output structure
All outputs are copied to the directory specified by --outdir.
results/
├── fastqc/
│   ├── sample_fastqc.html
│   └── sample_fastqc.zip
├── salmon/
│   └── sample_quant/
│       ├── quant.sf
│       └── logs/
├── sample_subsamp_info.txt
├── multiqc_report.html
└── multiqc_data/


## Notes 
The pipeline currently assumes single-end RNA-seq data.  
A Salmon index must already exist.  
Absolute paths are used for development and may be made relative in future versions.  
This workflow uses Nextflow DSL2.  