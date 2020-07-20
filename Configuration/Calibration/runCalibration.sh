#!/bin/bash

# This script will queue processes on the cluster up to the configured limit. The filenames
# will encode the values based using the name POPUATION-ACCESS-BETA-bfa.yml although a fixed
# study id is in place as well.

# The number of processes to run
LIMIT=40

# Iterate over the natural breaks in the popuation
for population in 797 1417 2279 3668 6386 12627 25584 53601 117418; do

  # Prepare the ASC file
  sed 's/#POPULATION#/'"$population"'/g' population.asc > $population.asc

  # Iterate off the possible levels of access
  for access in 0.5 0.65 0.7 0.75 0.8 0.85 0.9; do

    # Itterate over the possible beta values
    for beta in `seq 0.02 0.005 1.185`; do
      # Get the current job count, note the overcount due to the delay.
      # Wait if there are currently too many jobs
      while [ `qstat -u rbz5100 | grep rbz5100 | wc -l` -gt $LIMIT ]
      do
        sleep 10s
      done

      # Delete the jobs that have completed with no errors
      for item in `find . -name '*.pbs.e*' -size 0 | sed 's/\(.*\)\.pbs.e.*/\1.*/'`; do
        rm $item
      done

      # Prepare the configuration file
      sed 's/#BETA#/'"$beta"'/g' bf-calibration.yml > $population-$access-$beta-bfa.yml
      sed -i 's/#POPULATION#/'"$population"'/g' $population-$access-$beta-bfa.yml  
      sed -i 's/#ACCESS#/'"$access"'/g' $population-$access-$beta-bfa.yml
  
      sed 's/#BETA#/'"$beta"'/g' template.job > $population-$access-$beta-bfa.pbs
      sed -i 's/#POPULATION#/'"$population"'/g' $population-$access-$beta-bfa.pbs
      sed -i 's/#ACCESS#/'"$access"'/g' $population-$access-$beta-bfa.pbs
  
      # Queue the next item
      qsub $population-$access-$beta-bfa.pbs

    done
  done
done

