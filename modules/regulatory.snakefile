#MODULE: regulatory module--use BETA to calculate the Regulatory Potential

#PARAMETERS
_logfile="analysis/logs/regulatory.log"

def regulatory_targets(wildcards):
	"""Generates the targets for this module"""
	ls = []
    for run in config["runs"].keys():
        #NOTE: using the fact that _reps has this info parsed already!
        for rep in _reps[run]:
            #GENERATE Run name: concat the run and rep name
            runRep = "%s.%s" % (run, rep)
            ls.append("analysis/regulatory/%s/%s_gene_score_5fold.txt" % (runRep,runRep))
            ls.append("analysis/regulatory/%s/%s_gene_score.txt" % (runRep,runRep))
    return ls

rule regulatory_all:
    input:
        regulatory_targets

rule get_5Fold_Peaks:
    input:
        "analysis/peaks/{run}.{rep}/{run}.{rep}_peaks.xls"
    output:
    	temp("analysis/regulatory/{run}.{rep}/{run}.{rep}_5foldpeaks.bed")
    message: "REGULATORY: get 5 fold peaks"
    params:
        awkParams1 = "chr"
        awkParams2 = "#"
        awkParams3 = "\t"
    log:_logfile
    shell:
        "awk '($1 != {params.awkParams1} && $1 !={params.awkParams2} && $8 >= 5)' {input} | awk '{{OFS={params.awkParams3}; print $1,$2,$3,$10,$9}}' > {output}"

rule get_5Fold_Peaks_RP_Score:
    input:
        "analysis/regulatory/{run}.{rep}/{run}.{rep}_5foldpeaks.bed"
    output:
        "analysis/regulatory/{run}.{rep}/{run}.{rep}_gene_score_5fold.txt"
    params:
        pypath="PYTHONPATH=%s" % config["python2_pythonpath"],
        genome=""
    message: "REGULATORY: get RP score of 5 fold peaks"
    log:_logfile
    shell:
        "{params.pypath} cidc_chips/modules/scripts/motif_getSummary.py -t {input} -g {params.genome} -n {output} -d 100000"

rule get_top_peaks:
	input:
		"analysis/peaks/{run}.{rep}/{run}.{rep}_sort_peaks.narrowPeak"
	output:
		temp("analysis/regulatory/{run}.{rep}/{run}.{rep}_peaks_top_reg.bed")
	params:
		peaks: 10000
	log:_logfile
	message: "REGULATORY: get top summits for regpotential"
	shell:
		"head -n {param.peaks} {input} | cut -f 1,2,3,4,9 > {output}"

rule get_top_Peaks_RP_Score:
    input:
    	"analysis/regulatory/{run}.{rep}/{run}.{rep}_peaks_top_reg.bed"
    output:
    	"analysis/regulatory/{run}.{rep}/{run}.{rep}_gene_score.txt"
    params:
        pypath="PYTHONPATH=%s" % config["python2_pythonpath"],
        genome=""
    message: "REGULATORY: get RP score of top peaks"
    log:_logfile
    shell:
        "{params.pypath} cidc_chips/modules/scripts/motif_getSummary.py -t {input} -g {params.genome} -n {output} -d 100000"

