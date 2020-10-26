#!/bin/bash

# This script steps the model for a fixed number of replicates and increases to the treatment coverage.

LIMIT=90
REPLICATES=1

function run() {
  eval sequence=$1

  # Iterate over the requested sequences
  for rate in $sequence; do

    # Generate the YML and PBS files
    sed 's/#RATE#/'"$rate"'/g' bfa-study.yml > $rate-bfa.yml
    sed 's/#RATE#/'"$rate"'/g' template.job > $rate-bfa.pbs

    count=0
    while (($count < $REPLICATES)); do
      # Get the current job count, note the overcount due to the delay.
      # Wait if there are currently too many jobs, longer delay since we dont' 
      # expect these replicates to run quickly
      while [ `qstat -u rbz5100 | grep rbz5100 | wc -l` -gt $LIMIT ]; do
        sleep 300s
      done

      # Queue and increment
      qsub $rate-bfa.pbs
      ((count++))
    done
  done
}

run "\"0.005 0.01 0.015 0.02 0.025 0.03 0.035 0.04 0.045 0.05\""
