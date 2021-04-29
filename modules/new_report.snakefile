# Author: Len Taing, Clara Cousins, Gali Bai
# Last modified: 01/11/2021
#MODULE: Chips report module

# Import packages
import yaml
from yaml import dump as yaml_dump

def report_htmlTargets(wildcards):
    ls = []
    ls.append(output_path + "/report/Overview/01_chips_workflow.png")
    ls.append(output_path + "/report/Overview/01_details.yaml")
    ls.append(output_path + "/report/Overview/02_select_software_versions.tsv")
    ls.append(output_path + "/report/Overview/02_details.yaml")
    ls.append(output_path + "/report/Overview/03_assembly.csv")

    ls.append(output_path + "/report/Reads_Level_Quality/01_read_level_summary_table.dt")
    ls.append(output_path + "/report/Reads_Level_Quality/01_details.yaml")
    ls.append(output_path + "/report/Reads_Level_Quality/02_mapped_reads_bar.plotly")
    ls.append(output_path + "/report/Reads_Level_Quality/02_details.yaml")
    #ls.append(output_path + "/report/Reads_Level_Quality/02_mapped_reads_bar.plotly")
    return ls

rule report_all:
    input:
        output_path+ "/report/report.html"

########################### OVERVIEW Section ##################################
rule report_overview_workflow:
    input:
        png="cidc_chips/report/chips_workflow.png",
        yml="cidc_chips/report/intro_details.yaml",
    output:
        png = output_path + "/report/Overview/01_chips_workflow.png",
        det = output_path + "/report/Overview/01_details.yaml",
    shell:
        "cp {input.png} {output.png} && cp {input.yml} {output.det}"

rule report_overview_software_versions:
    #inpuy: #NO Input
    output:
        tsv=output_path + "/report/Overview/02_select_software_versions.tsv",
        details=output_path + "/report/Overview/02_details.yaml",
    params:
        caption="""caption: 'The details of other software used in CHIPs are written to software_versions_all.txt in the directory where this report was generated.'"""
    shell:
        """echo "{params.caption}" >> {output.details} && """
        """cidc_chips/modules/scripts/report/overview/software_versions.py -o {output.tsv}"""

rule report_overview_assembly:
    #inpuy: #NO Input
    output:
        output_path + "/report/Overview/03_assembly.csv",
    params:
        assembly=config['assembly']
    shell:
        "echo {params.assembly} > {output}"
########################### END OVERVIEW Section ##############################

########################### Read Level Quality Section ########################
#GALI start here
rule report_read_level_summary_table:
    input:
        mapping=output_path + "/align/mapping.csv",
        pbc=output_path + "/frips/pbc.csv",
    output:
        csv=output_path + "/report/Reads_Level_Quality/01_read_level_summary_table.dt",
        details=output_path + "/report/Reads_Level_Quality/01_details.yaml",
    params:
        caption="""caption: 'Abbreviations: M, million; PBC, PCR bottlneck coefficient.'"""
    shell:
        """echo "{params.caption}" >> {output.details} && """
        """cidc_chips/modules/scripts/report/read_level_quality/read_level_summary.py -m {input.mapping} -p {input.pbc} -o {output.csv}"""

rule report_mapped_reads_bar:
    input:
        output_path + "/align/mapping.csv",
    output:
        csv=output_path + "/report/Reads_Level_Quality/02_mapped_reads_bar.plotly",
        details=output_path + "/report/Reads_Level_Quality/02_details.yaml",
    params:
        caption="""caption: 'Mapped reads refer to the number of reads successfully mapping to the genome, while uniquely mapped reads are the subset of mapped reads mapping only to one genomic location.'""",
        plot_options = yaml_dump({'plotly': {'barmode':"overlay",'opacity':1.0, 'orientation': "h", 'labels':{'X':'Number of reads','value':'Number of reads'}}}),
    shell:
        """echo "{params.caption}" >> {output.details} && """
        """echo "{params.plot_options}" >> {output.details} &&"""
        """cp {input} {output.csv}"""

########################### END Read Level Quality Section ####################

rule report_auto_render:
    """Generalized rule to dynamically generate the report BASED
    on what is in the report directory"""
    input:
        report_htmlTargets
    params:
        jinja2_template="cidc_chips/report/index.sample.html",
        output_path = output_path + "/report",
        #sections_list=",".join(['Overview', "Reads_Level_Quality", "Peaks_Level_Quality", "Genome_Track_View","Downstream"]), #define sections order here
        sections_list=",".join(['Overview','Reads_Level_Quality']), #define sections order here
        title="CHIPs Report",
    output:
        output_path+ "/report/report.html"
    message:
        "REPORT: Generating example report"
    shell:
        """python cidc_chips/modules/scripts/report.py -d {params.output_path} -s {params.sections_list} -j {params.jinja2_template} -t "{params.title}" -o {output} && cp -r cidc_chips/report/static {params.output_path}"""
