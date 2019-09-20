#MODULE: targets module--use BETA to calculate the Regular Potential

#PARAMETERS
# _logfile=output_path + "/logs/targets.log"

target_decay_rate = 10000

def targets_targets(wildcards):
    """Generates the targets for this module"""
    ls = []
    for run in config["runs"].keys():
        #NOTE: using the fact that _reps has this info parsed already!
        for rep in _reps[run]:
            #GENERATE Run name: concat the run and rep name
            runRep = "%s.%s" % (run, rep)
            ls.append(output_path + "/targets/%s/%s_gene_score_5fold.txt" % (runRep,runRep))
            ls.append(output_path + "/targets/%s/%s_gene_score.txt" % (runRep,runRep))
    return ls

rule targets_all:
    input:
        targets_targets

rule targets_get5FoldPeaks:
    input:
        # output_path + "/peaks/{run}.{rep}/{run}.{rep}_peaks.xls"
        output_path + "/peaks/{run}.{rep}/{run}.{rep}_peaks.bed"
    output:
        output_path + "/targets/{run}.{rep}/{run}.{rep}_5foldpeaks.bed"
    message: "REGULATORY: get 5 fold peaks"
    log:output_path + "/logs/targets/{run}.{rep}.log"
    shell:
        # """awk '($1 != "chr" && $1 !="#" && $8 >= 5)' {input} | awk '{{OFS="\\t"; print $1,$2,$3,$10,$9}}' > {output}"""
        "awk '($5 >= 5)' {input} > {output}"

rule targets_get5FoldPeaksRPScore:
    input:
        output_path + "/targets/{run}.{rep}/{run}.{rep}_5foldpeaks.bed"
    output:
        output_path + "/targets/{run}.{rep}/{run}.{rep}_gene_score_5fold.txt"
    params:
        pypath="PYTHONPATH=%s" % config["python2_pythonpath"],
        genome=config['geneTable'],
        decay=target_decay_rate
    message: "REGULATORY: get RP score of 5 fold peaks"
    log:output_path + "/logs/targets/{run}.{rep}.log"
    shell:
        "{params.pypath} cidc_chips/modules/scripts/targets_getRP.py -t {input} -g {params.genome} -n {output} -d {params.decay}"

rule targets_getTopPeaks:
    input:
        output_path + "/peaks/{run}.{rep}/{run}.{rep}_sorted_peaks.bed"
    output:
        output_path + "/targets/{run}.{rep}/{run}.{rep}_peaks_top_reg.bed"
    params:
        peaks = 10000
    log:output_path + "/logs/targets/{run}.{rep}.log"
    message: "REGULATORY: get top summits for regpotential"
    shell:
        "head -n {params.peaks} {input} > {output}"

rule targets_getTopPeaksRPScore:
    input:
        output_path + "/targets/{run}.{rep}/{run}.{rep}_peaks_top_reg.bed"
    output:
        output_path + "/targets/{run}.{rep}/{run}.{rep}_top10k_gene_score.txt"
    params:
        pypath="PYTHONPATH=%s" % config["python2_pythonpath"],
        genome=config['geneTable'],
        decay=target_decay_rate
    message: "REGULATORY: get RP score of top peaks"
    log:output_path + "/logs/targets/{run}.{rep}.log"
    shell:
        "{params.pypath} cidc_chips/modules/scripts/targets_getRP.py -t {input} -g {params.genome} -n {output} -d {params.decay}"


rule targets_getAllPeaksRPScore:
    input:
        output_path + "/peaks/{run}.{rep}/{run}.{rep}_sorted_peaks.bed"
    output:
        output_path + "/targets/{run}.{rep}/{run}.{rep}_gene_score.txt"
    params:
        pypath="PYTHONPATH=%s" % config["python2_pythonpath"],
        genome=config['geneTable'],
        decay=target_decay_rate
    message: "REGULATORY: get RP score of all peaks"
    log:output_path + "/logs/targets/{run}.{rep}.log"
    shell:
        "{params.pypath} cidc_chips/modules/scripts/targets_getRP.py -t {input} -g {params.genome} -n {output} -d {params.decay}"
