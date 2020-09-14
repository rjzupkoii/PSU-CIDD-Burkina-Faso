#!/bin/bash

# This script steps the model for a fixed number of replicates and increases to the treatment coverage.

LIMIT=90
REPLICATES=10

function run() {
  eval sequence=$1

  # Iterate over the requested sequences
  for rate in $sequence; do

    # Generate the YML and PBS files
    sed 's/#MUTATION#/'"$rate"'/g' bfa-study.yml > $rate-bfa.yml
    sed 's/#MUTATION#/'"$rate"'/g' template.job > $rate-bfa.pbs

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

run "\"0.001983 0.0001983\""
