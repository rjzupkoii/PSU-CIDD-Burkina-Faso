#!/bin/bash

# This script will queue processes on the cluster up to the configured limit. The filenames
# will encode the values based using the name ZONE-POPUATION-ACCESS-BETA-bfa.yml although a fixed
# study id is in place as well.

# Get the current job count, note the overcount due to the delay.
# Wait if there are currently too many jobs
LIMIT=75
function check_delay {
  while [ `qstat -u rbz5100 | grep rbz5100 | wc -l` -gt $LIMIT ]; do
    sleep 10s
  done
}

function generateAsc() {
  eval populations=$1
  for population in $populations; do
    sed 's/#POPULATION#/'"$population"'/g' population.asc > $population.asc
  done
}

function run() {
  eval zone=$1
  eval population_list=$2
  eval treatment_list=$3

  echo "Running zone, $zone"
  sed 's/#ZONE#/'"$zone"'/g' zone.asc > $zone.asc
  for population in $population_list; do
    for access in $treatment_list; do
      for beta in `seq 0.05 0.05 1.20`; do
        check_delay

        # Prepare the configuration file
        sed 's/#BETA#/'"$beta"'/g' bfa-calibration.yml > $zone-$population-$access-$beta-bfa.yml
        sed -i 's/#POPULATION#/'"$population"'/g' $zone-$population-$access-$beta-bfa.yml  
        sed -i 's/#ACCESS#/'"$access"'/g' $zone-$population-$access-$beta-bfa.yml
        sed -i 's/#ZONE#/'"$zone"'/g' $zone-$population-$access-$beta-bfa.yml
    
        sed 's/#BETA#/'"$beta"'/g' template.job > $zone-$population-$access-$beta-bfa.pbs
        sed -i 's/#POPULATION#/'"$population"'/g' $zone-$population-$access-$beta-bfa.pbs
        sed -i 's/#ACCESS#/'"$access"'/g' $zone-$population-$access-$beta-bfa.pbs
        sed -i 's/#ZONE#/'"$zone"'/g' $zone-$population-$access-$beta-bfa.pbs
    
        # Queue the next item
        qsub $zone-$population-$access-$beta-bfa.pbs
      done
    done
  done
}

generateAsc "\"797 1417 2279 3668 6386 12627 25584 53601 117418\""
run 0 "\"797 1417 2279 3668 6386 12627\"" "\"0.75 0.8 0.85\""
run 1 "\"797 1417 2279 3668 6386 12627 25584 53601 117418\"" "\"0.6 0.65 0.7 0.75 0.8 0.85 0.9\""
run 2 "\"797 1417 2279 3668 6386 12627 25584 53601\"" "\"0.6 0.65 0.7 0.8 0.85 0.9\""
