#!/bin/bash
##########
#The MIT License (MIT)
#
# Copyright (c) 2015 Aiden Lab
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
##########
# Juicer postprocessing script.
# This will run the major post-processing on the HiC file, including finding
# loops with HiCCUPS and inding motifs of these loops with MotifFinder.
# Juicer 1.5
## Read arguments
usageHelp="Usage: ${0} [-h] -j <juicebox_file_path> -i <hic_file_path> -m <bed_file_dir> -g <genome ID>"

printHelpAndExit() {
    echo "$usageHelp"
    exit $1
}

#set defaults
genomeID="hg19"
hic_file_path="$(pwd)/aligned/inter_30.hic"
juiceboxpath="/broad/aidenlab/scripts/juicebox"
bed_file_dir="/broad/aidenlab/references/motif"

while getopts "h:g:j:i:m:" opt; do
    case $opt in
	h) printHelpAndExit 0;;
	j) juiceboxpath=$OPTARG ;;
	i) hic_file_path=$OPTARG ;;
	m) bed_file_dir=$OPTARG ;; 
	g) genomeID=$OPTARG ;;
	[?]) printHelpAndExit 1;;
    esac
done

## Check that juicebox exists 
if [ ! -e "${juiceboxpath}" ]; then
  echo "***! Can't find juicebox in ${juiceboxpath}";
  exit 100;
fi

## Check that hic file exists    
if [ ! -e "${hic_file_path}" ]; then
  echo "***! Can't find inter.hic in ${hic_file_path}";
  exit 100;
fi

## Check that bed folder exists    
if [ ! -e "${bed_file_dir}" ]; then
  echo "***! Can't find folder ${bed_file_dir}";
  exit 100;
fi

echo -e "\nHiCCUPS:\n"
${juiceboxpath} hiccups ${hic_file_path} ${hic_file_path%.*}"_loops.txt"
if [ $? -ne 0 ]; then
    echo "***! Problem while running HiCCUPS";
    exit 100
fi

if [ -f ${hic_file_path%.*}"_loops.txt" ]
then
    echo -e "\nAPA:\n"
    ${juiceboxpath} apa ${hic_file_path} ${hic_file_path%.*}"_loops.txt" "apa_results"
    echo -e "\nMOTIF FINDER:\n"
    ${juiceboxpath} motifs ${genomeID} ${bed_file_dir} ${hic_file_path%.*}"_loops.txt"
    echo -e "\n(-: Feature annotation successfully completed (-:"
else
    # if loop lists do not exist but Juicebox didn't return an error, likely 
    # too sparse
    echo -e "\n(-: Postprocessing successfully completed, maps too sparse to annotate (-:"
fi
