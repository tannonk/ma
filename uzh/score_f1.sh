#!/bin/bash

## To call:
## bash score_f1.sh <decode directory> <norm2dieth mapping file>
## e.g. uzh/score_f1.sh /mnt/tannon/processed/archimob_r1/orig/decode_out/decode /mnt/tannon/corpus_data/norm2dieth.json

## Author: Tannon Kew (tkew@uzh.ch)

set -e

##################
## Input arguments
##################

decode_dir=$1
n2d_mapping=$2

###############
## Intermediate
###############

# infer the min and max lmwt that need to be rescored from files
# in wer decode_dir
min_lmwt=100
max_lmwt=0

for f in $decode_dir/wer_*; do
    f=$(basename $f)
    lmwt=`echo $f | cut -d'_' -f2`
    (( $lmwt > $max_lmwt )) && max_lmwt=$lmwt
    (( $lmwt < $min_lmwt )) && min_lmwt=$lmwt
done

if [[ min_lmwt -eq 100 ]]; then
    echo "ERROR: Could not infer MIN LMWT value." && exit 1;
elif [[ max_lmwt -eq 0 ]]; then
    echo "ERROR: Could not infer MAX LMWT value." && exit 1;
else
    echo "min LMWT = $min_lmwt"
    echo "max LMWT = $max_lmwt"
fi

scoring_dir=$decode_dir/scoring_kaldi
word_ins_penalty=0.0,0.5,1.0

for wip in $(echo $word_ins_penalty | sed 's/,/ /g'); do
  for lmwt in $(seq $min_lmwt $max_lmwt); do
    hyp_file="$scoring_dir/penalty_$wip/$lmwt.txt"
    output_file="$decode_dir/f1_${lmwt}_${wip}"
    [ ! -f $hyp_file ] && echo -e "ERROR: Missing file $hyp_file" && exit 1;
    echo "Scoring $hyp_file..."
    python3 evaluation/scherrer_eval.py \
    --ref $scoring_dir/test_filt.txt \
    --hyp $hyp_file \
    -d $n2d_mapping \
    > $output_file
  done
done
