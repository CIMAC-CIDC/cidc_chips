#REPORT module - must come last in includes!
import sys
from string import Template
from snakemake.utils import report
from snakemake.report import data_uri_from_file

#DEPENDENCIES
from tabulate import tabulate

_ReportTemplate = Template(open("cidc_chips/static/chips_report.txt").read())
_logfile = output_path + "/logs/report.log"

def report_targets(wildcards):
    """Generates the targets for this module"""
    ls = []
    ls.append(output_path + '/report/sequencingStatsSummary.csv')
    ls.append(output_path + '/report/peaksSummary.csv')
    ls.append(output_path + '/report/report.html')
    return ls

def csvToSimpleTable(csv_file):
    """function to translate a .csv file into a reStructuredText simple table
    ref: http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html#simple-tables
    """
    #read in file
    f = open(csv_file)
    stats = [l.strip().split(",") for l in f]
    f.close()

    hdr = stats[0]
    rest = stats[1:]
    #RELY on the tabulate pkg
    ret = tabulate(rest, hdr, tablefmt="rst")
    return ret

def processRunInfo(run_info_file):
    """extracts the macs version and the fdr used first and second line"""
    f = open(run_info_file)
    ver = f.readline().strip()
    fdr = f.readline().strip()
    return (ver,fdr)

def genPeakSummitsTable(conservPlots,motifSummary):
    """generates rst formatted table that will contain the conservation plot
    and motif analysis for ALL runs
    hdr = array of header/column elms
    """
    #parse MotifSummary
    motifs = parseMotifSummary(motifSummary) if motifSummary else {}
    runs = sorted(_getRepInput("$runRep"))
    #HEADER- PROCESS the different modules differently
    if 'motif' in config and config['motif'] == 'mdseqpos':
        hdr = ["Run", "Conservation","MotifID","MotifName","Logo","Zscore"]
    else:
        hdr = ["Run", "Conservation","Motif","Logo","Pval","LogPval"]
    #BUILD up the rest of the table
    rest = []
    for run,img in zip(runs,conservPlots):
        #HANDLE null values
        if img and (img != 'NA'):
            conserv = ".. image:: %s" % data_uri_from_file(img)[0]
        else:
            conserv = "NA"
        #HANDLE null values--Also check that we're doing motif analysis
        if 'motif' in config and motifs[run]['logo'] and (motifs[run]['logo'] != 'NA'):
            motif_logo = ".. image:: %s" % data_uri_from_file(motifs[run]['logo'])[0]
        else:
            motif_logo = "NA"

        #PROCESS the different modules differently
        if 'motif' in config:
            if config['motif'] == 'mdseqpos':
                rest.append([run, conserv, motifs[run]['motifId'], motifs[run]['motifName'], motif_logo,  motifs[run]['zscore']])
            else:
                rest.append([run, conserv, motifs[run]['motifName'], motif_logo, motifs[run]['pval'],motifs[run]['logp']])
        else:
            #motif analysis was skipped
            rest.append([run, conserv, 'NA', 'NA', 'NA','NA'])

    ret = tabulate(rest, hdr, tablefmt="rst")
    return ret

def parseMotifSummary(motif_csv):
    """Given a motifSummary.csv file, parses this into a dictionary 
    {run: {motifId: , motifName: , logo: , zscore: }}
    Returns this dictionary
    """
    ret = {}
    f = open(motif_csv)
    hdr = f.readline().strip().split(",")
    for l in f:
        tmp = l.strip().split(",")
        if config['motif'] == 'mdseqpos':
            ret[tmp[0]] = {'motifId': tmp[1], 'motifName': tmp[2], 'logo': tmp[3], 'zscore': tmp[4]}
        else:
            ret[tmp[0]] = {'motifName':tmp[1], 'logo':tmp[2], 'pval': tmp[3], 'logp': tmp[4]}
    f.close()
    return ret

def sampleGCandContam_table(fastqc_stats, fastqc_gc_plots, contam_table):
    """generates rst formatted table that will contain the fastqc GC dist. plot
    for all samples
    hdr = array of header/column elms
    NOTE: we use the thumb nail image for the GC content plots
    """
    #READ in fastqc_stats
    f_stats = {}
    f = open(fastqc_stats)
    hdr = f.readline().strip().split(",")  #largely ignored
    for l in f:
        tmp = l.strip().split(",")
        #store GC content, 3 col, using sample names as keys
        f_stats[tmp[0]] = tmp[2]
    f.close()
    
    #READ in contam_panel
    contam = {}
    f = open(contam_table)
    hdr = f.readline().strip().split(',') #We'll use this!
    species = hdr[1:]
    for l in f:
        tmp = l.strip().split(",")
        #build dict, use sample name as key
        contam[tmp[0]] = zip(species, tmp[1:]) #dict of tupes, (species, %)
    f.close()

    #PUT GC plots into a dictionary--keys are sample names
    plots = {}
    for p in fastqc_gc_plots:
        #NOTE the path structure is analysis/fastqc/{sample}/png_filename
        #we take second to last
        tmp = p.split("/")[-2]
        plots[tmp] = str(p)
    
    #build output
    ret=[]
    samples = sorted(list(f_stats.keys()))
    hdr = ["Sample", "GC median", "GC distribution"]
    hdr.extend(species)
    rest=[]

    for sample in samples:
        #HANDLE null values
        if plots[sample] and (plots[sample] != 'NA'):
            gc_plot = ".. image:: %s" % data_uri_from_file(plots[sample])[0]
        else:
            gc_plot = "NA"
        #get rest of values and compose row
        contam_values = [v for (s, v) in contam[sample]]
        row = [sample, f_stats[sample], gc_plot]
        row.extend(contam_values)

        rest.append(row)
    ret = tabulate(rest, hdr, tablefmt="rst")
    return ret

def getReportInputs(wildcards):
    """Input function created just so we can switch-off motif analysis"""
    ret = {'cfce_logo':"cidc_chips/static/CFCE_Logo_Final.jpg",
           'run_info':output_path + "/peaks/run_info.txt",
           'map_stat':output_path + "/report/mapping.png",
           'pbc_stat':output_path + "/report/pbc.png",
           'peakFoldChange_png':output_path + "/report/peakFoldChange.png",
           'conservPlots': sorted(_getRepInput(output_path + "/conserv/$runRep/$runRep_conserv_thumb.png")),
           'samples_summary':output_path + "/report/sequencingStatsSummary.csv",
           'runs_summary':output_path + "/report/peaksSummary.csv",
           'contam_panel':output_path + "/contam/contamination.csv",
           #MOTIF handled after
           'fastqc_stats':output_path + "/fastqc/fastqc.csv",
           'fastqc_gc_plots': expand(output_path + "/fastqc/{sample}/{sample}_perSeqGC_thumb.png", sample=config["samples"])
           }
    if 'motif' in config:
        ret['motif'] = output_path + "/motif/motifSummary.csv"
    return ret


rule report_all:
    input:
        report_targets

rule report:
    input:
        unpack(getReportInputs)
    params:
        #OBSOLETE, but keeping around
        samples = config['samples']
   # conda: "../envs/report/report.yaml"
    output: html=output_path + "/report/report.html"
    run:
        (macsVersion, fdr) = processRunInfo(input.run_info)
        samplesSummaryTable = csvToSimpleTable(input.samples_summary)
        runsSummaryTable = csvToSimpleTable(input.runs_summary)
        #HACK b/c unpack is ruining the input.fastqc_gc_plots element--the list
        #becomes a singleton
        conservPlots = sorted(_getRepInput(output_path + "/conserv/$runRep/$runRep_conserv_thumb.png"))
        if 'motif' in config:
            peakSummitsTable = genPeakSummitsTable(conservPlots, input.motif)
        else:
            peakSummitsTable = genPeakSummitsTable(conservPlots, None)
        #HACK b/c unpack is ruining the input.fastqc_gc_plots element--the list
        #becomes a singleton
        fastqc_gc_plots = [output_path + "/fastqc/%s/%s_perSeqGC_thumb.png" % (s,s) for s in config['samples']]
        sampleGCandContam = sampleGCandContam_table(input.fastqc_stats, fastqc_gc_plots, input.contam_panel)
        git_commit_string = "XXXXXX"
        git_link = 'https://bitbucket.org/plumbers/cidc_chips/commits/'
        #Check for .git directory
        if os.path.exists("cidc_chips/.git"):
            git_commit_string = subprocess.check_output('git --git-dir="cidc_chips/.git" rev-parse --short HEAD',shell=True).decode('utf-8').strip()
            git_link = git_link + git_commit_string
        tmp = _ReportTemplate.substitute(cfce_logo=data_uri_from_file(input.cfce_logo)[0],map_stat=data_uri_from_file(input.map_stat)[0],
                                         pbc_stat=data_uri_from_file(input.pbc_stat)[0],peakSummitsTable=peakSummitsTable,
                                         peakFoldChange_png=data_uri_from_file(input.peakFoldChange_png)[0],
                                         git_commit_string=git_commit_string,git_link=git_link)
        report(tmp, output.html, stylesheet='./cidc_chips/static/chips_report.css', metadata="Len Taing", **input)

rule samples_summary_table:
    input:
        fastqc = output_path + "/fastqc/fastqc.csv",
        mapping = output_path + "/align/mapping.csv",
        pbc = output_path + "/frips/pbc.csv",
    output:
        output_path + "/report/sequencingStatsSummary.csv"
    log: _logfile
    #conda: "../envs/report/report.yaml"
    shell:
        "cidc_chips/modules/scripts/get_sampleSummary.py -f {input.fastqc} -m {input.mapping} -p {input.pbc} > {output} 2>>{log}"

rule runs_summary_table:
    input:
        peaks = output_path + "/peaks/peakStats.csv",
        frips = output_path + "/frips/frips.csv",
        dhs = output_path + "/ceas/dhs.csv",
        meta = output_path + "/ceas/meta.csv",
    output:
        output_path + "/report/peaksSummary.csv"
    log: _logfile
    #conda: "../envs/report/report.yaml"
    shell:
        "cidc_chips/modules/scripts/get_runsSummary.py -p {input.peaks} -f {input.frips} -d {input.dhs} -m {input.meta} -o {output} 2>>{log}"

######## PLOTS ######
rule plot_map_stat:
    input:
        output_path + "/align/mapping.csv"
    output:
        output_path + "/report/mapping.png"
    log: _logfile
    conda: "../envs/report/report.yaml"
    shell:
        "Rscript cidc_chips/modules/scripts/map_stats.R {input} {output}"

rule plot_pbc_stat:
    input:
        #output_path + "/align/pbc.csv"
        output_path + "/frips/pbc.csv"
    output:
        output_path + "/report/pbc.png"
    log: _logfile
    conda: "../envs/report/report.yaml"
    shell:
        "Rscript cidc_chips/modules/scripts/plot_pbc.R {input} {output}"

rule plot_peakFoldChange:
    input: 
        output_path + "/peaks/peakStats.csv"
    output:
        output_path + "/report/peakFoldChange.png"
    log: _logfile
    conda: "../envs/report/report.yaml"
    shell:
        "Rscript cidc_chips/modules/scripts/plot_foldChange.R {input} {output}"

#DEPRECATED!! this plot is no longer used!
rule plot_nonChrM_stats:
    input:
        output_path + "/frips/nonChrM_stats.csv"
    output:
        output_path + "/report/attic/nonChrM_stats.png"
    log: _logfile
    conda: "../envs/report/report.yaml"
    shell:
        "Rscript cidc_chips/modules/scripts/plot_nonChrM.R {input} {output}"

