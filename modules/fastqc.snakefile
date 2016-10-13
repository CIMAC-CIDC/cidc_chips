#MODULE: fastqc- sequence quality scores
#RULES:
#    sample_fastq: subsample 100k reads from each sample to perform fastqc analysis

def getFastq3(wildcards):
    """Get associated fastqs for each sample.  
    NOTE: if PE, take the first pair"""
    s = config["samples"][wildcards.sample]
    return s[0]

rule fastqc_all:
    input:
        #expand("analysis/align/{sample}/{sample}_100k.fastq", sample=config["samples"]),
        #expand("analysis/fastqc/{sample}_100k_fastqc", sample=config["samples"]),
        #expand("analysis/fastqc/{sample}_perSeqQual.txt", sample=config["samples"]),
        expand("analysis/fastqc/{sample}_perSeqGC.txt", sample=config["samples"]),
        #"analysis/align/mapping.csv"

rule sample_fastq:
    """Subsample fastq"""
    input:
        getFastq3
    output:
        "analysis/align/{sample}/{sample}_100k.fastq"
    params:
        seed=11,
        #how many to sample
        size=100000
    shell:
        "seqtk sample -s {params.seed} {input} {params.size} > {output}"

rule call_fastqc:
    """CALL FASTQC on each sub-sample"""
    input:
        "analysis/align/{sample}/{sample}_100k.fastq"
    output:
        "analysis/fastqc/{sample}_100k_fastqc"
    #threads:
    shell:
        "fastqc {input} --extract -o analysis/fastqc"

rule get_PerSequenceQual:
    """extract per sequence quality from fastqc_data.txt"""
    input:
        "analysis/fastqc/{sample}_100k_fastqc/fastqc_data.txt"
    output:
        "analysis/fastqc/{sample}_perSeqQual.txt"
    params:
        #DON'T forget quotes
        section="'Per sequence quality'"
    shell:
        "chips/modules/scripts/fastqc_data_extract.py -f {input} -s {params.section} > {output}"

rule get_PerSequenceGC:
    """extract per sequence GC contentfrom fastqc_data.txt"""
    input:
        "analysis/fastqc/{sample}_100k_fastqc/fastqc_data.txt"
    output:
        "analysis/fastqc/{sample}_perSeqGC.txt"
    params:
        #DON'T forget quotes
        section="'Per sequence GC content'"
    shell:
        "chips/modules/scripts/fastqc_data_extract.py -f {input} -s {params.section} > {output}"

