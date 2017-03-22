#MODULE: PEAK CALLING using macs2

#PARAMETERS
_logfile="analysis/logs/peaks.log"
_macs_fdr="0.01"
_macs_keepdup="1"
_macs_extsize="146"
_macs_species="hs"

#TODO: handle control
def getTreats(wildcards):
    r = config['runs'][wildcards.run]
    #convert SAMPLE names to BAMS
    tmp = ["analysis/align/%s/%s.sorted.bam" % (s,s) for s in r[:2] if s]
    #print("TREATS: %s" % tmp)
    return tmp

def getConts(wildcards):
    r = config['runs'][wildcards.run]
    #convert SAMPLE names to BAMS
    tmp = ["analysis/align/%s/%s.sorted.bam" % (s,s) for s in r[2:4] if s]
    #print("CONTS: %s" % tmp)
    return tmp

def peaks_targets(wildcards):
    """Generates the targets for this module"""
    ls = []
    for run in config["runs"].keys():
        #ls.append("analysis/peaks/%s/%s_peaks.bed" % (run,run))
        ls.append("analysis/peaks/%s/%s_sorted_peaks.narrowPeak" % (run,run))
        ls.append("analysis/peaks/%s/%s_sorted_peaks.narrowPeak.bed" % (run,run))
        ls.append("analysis/peaks/%s/%s_sorted_summits.bed" % (run,run))
        ls.append("analysis/peaks/%s/%s_treat_pileup.bw" % (run,run))
        ls.append("analysis/peaks/%s/%s_control_lambda.bw" % (run,run))
    ls.append("analysis/peaks/peakStats.csv")
    return ls

rule peaks_all:
    input:
        peaks_targets

rule macs2_callpeaks:
    input:
        treat=getTreats,
        cont=getConts
    output:
        "analysis/peaks/{run}/{run}_peaks.narrowPeak",
        "analysis/peaks/{run}/{run}_peaks.xls",
        "analysis/peaks/{run}/{run}_summits.bed",
        "analysis/peaks/{run}/{run}_treat_pileup.bdg",
        "analysis/peaks/{run}/{run}_control_lambda.bdg",
    params:
        fdr=_macs_fdr,
        keepdup=_macs_keepdup,
        extsize=_macs_extsize,
        species=_macs_species,
        outdir="analysis/peaks/{run}/",
        name="{run}"
    message: "PEAKS: calling peaks with macs2"
    log:_logfile
    run:
        #NOTE: TODO- handle broadPeak calling!
        treatment = "-t %s" % " ".join(input.treat) if input.treat else "",
        control = "-c %s" % " ".join(input.cont) if input.cont else ""
        shell("macs2 callpeak --SPMR -B -q {params.fdr} --keep-dup {params.keepdup} -g {params.species} --extsize {params.extsize} --nomodel {treatment} {control} --outdir {params.outdir} -n {params.name} 2>>{log}")


rule peakToBed:
    input:
        "analysis/peaks/{run}/{run}_sorted_peaks.narrowPeak"
    output:
        "analysis/peaks/{run}/{run}_sorted_peaks.narrowPeak.bed"
    message: "PEAKS: Converting peak file to bed file"
    log:_logfile
    shell:
        "cut -f1,2,3,4,9 {input} > {output} 2>>{log}"

rule sortSummits:
    input:
        "analysis/peaks/{run}/{run}_summits.bed"
    output:
        "analysis/peaks/{run}/{run}_sorted_summits.bed"
    message: "PEAKS: sorting the summits bed by score"
    log:_logfile
    shell:
        "sort -r -n -k 5 {input} > {output} 2>>{log}"

rule sortNarrowPeaks:
    input:
        "analysis/peaks/{run}/{run}_peaks.narrowPeak"
    output:
        "analysis/peaks/{run}/{run}_sorted_peaks.narrowPeak"
    message: "PEAKS: sorting the narrowPeaks by -log10qval (col9)"
    log:_logfile
    shell:
        "sort -r -n -k 9 {input} > {output} 2>>{log}"

rule sortBedgraphs:
    """Sort bed graphs--typically useful for converting bdg to bw"""
    input:
        "analysis/peaks/{run}/{run}_{suffix}.bdg"
    output:
        "analysis/peaks/{run}/{run}_{suffix}.sorted.bdg"
    message: "PEAKS: sorting bdg pileups"
    log:_logfile
    shell:
        "bedSort {input} {output} 2>>{log}"

rule bdgToBw:
    """Convert bedGraphs to BigWig"""
    input:
        "analysis/peaks/{run}/{run}_{suffix}.sorted.bdg"
    output:
        "analysis/peaks/{run}/{run}_{suffix}.bw"
    params:
        chroms=config['chrom_lens']
    message: "PEAKS: Convert bedGraphs to BigWig"
    log:_logfile
    shell:
        "bedGraphToBigWig {input} {params.chroms} {output} 2>>{log}"

rule getPeaksStats:
    """Counts  number of peaks, # of 10FC, # of 20FC peaks for each sample"""
    input:
        expand("analysis/peaks/{run}/{run}_sorted_peaks.narrowPeak", run=config['runs'])
    output:
        "analysis/peaks/peakStats.csv"
    message: "PEAKS: collecting peaks stats for each run"
    log:_logfile
    run:
        files = " -f ".join(input)
        shell("chips/modules/scripts/peaks_getPeakStats.py -f {files} -o {output} 2>>{log}")
