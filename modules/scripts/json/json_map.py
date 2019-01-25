#!/usr/bin/env python
#porting from https://github.com/cfce/chilin/blob/master/chilin2/modules/bwa/qc.py
from optparse import OptionParser
import sys
import os
import json

def json_dump(json_dict):   # json
    """
    dump out uniform json files for collecting statistics
    :param json_dict: output python dict to json
    :return: json_file name
    """
    json_file = json_dict["output"]["json"]
    with open(json_file, "w") as f:
        json.dump(json_dict, f, indent=4)
    return json_file

def json_map(options):
    """
    input samtools flagstat standard output
    output json files
    kwargs for matching replicates order
    keep one value for each json for easier loading to html/pdf template
    example:
    3815725 + 0 in total (QC-passed reads + QC-failed reads)
    0 + 0 duplicates
    3815723 + 0 mapped (100.00%:-nan%)
    """
    input={"mapped_txt": str(os.path.abspath(options.input))}
    output={"json": str(os.path.abspath(options.output))}
    # param={"sample": options.samples}

    json_dict = {"stat": {}, "input": input, "output": output, "param": {}}
    #UGH: this script is ugly!!
    #TRY to infer the SAMPLE NAMES--SAMPLE.virusseq.ReadsPerGene.out.tab
    sampleID = input["mapped_txt"].strip().split("/")[-1].split('.')[0]
    # print(sampleID)
    #ALSO remove the suffix '_mapping' from the sampleID name
    if sampleID.endswith('_mapping'):
        sampleID = sampleID.replace("_mapping","")
    with open(input["mapped_txt"]) as f:
        total = int(f.readline().strip().split()[0])
        #skip 3 lines
        l = f.readline()
        l = f.readline()
        l = f.readline()
        mapped = int(f.readline().strip().split()[0])
    json_dict["stat"][sampleID] = {}
    json_dict["stat"][sampleID]["mapped"] = mapped
    json_dict["stat"][sampleID]["total"] = total
    json_dict["param"]["sample"]=sampleID
    # for mapped, total, sam in zip(input["bwa_mapped"], input["bwa_total"], param["sample"]):
    #     inft = open(total, 'rU')
    #     infm = open(mapped, 'rU')
    #     json_dict["stat"][sam] = {}
    #     json_dict["stat"][sam]["mapped"] = int(infm.readlines()[2].split()[0])
    #     json_dict["stat"][sam]["total"] = int(inft.readlines()[0].strip())
    #     inft.close()
    #     infm.close()
    json_dump(json_dict)



def main():
    USAGE=""
    optparser = OptionParser(usage=USAGE)
    optparser.add_option("-i", "--input", help="input text files")
    optparser.add_option("-o", "--output", help="output files")
    (options, args) = optparser.parse_args(sys.argv)
    json_map(options)


if __name__ == '__main__':
    main()
