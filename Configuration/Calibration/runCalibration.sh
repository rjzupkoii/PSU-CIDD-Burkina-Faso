#!/bin/bash

# The number of processes to run
LIMIT=40

# Run using ten natural breaks
for population in 797 1417 2279 3668 6386 12627 25584 53601 117418; do

  # Prepare the ASC file
  sed 's/#POPULATION#/'"$population"'/g' population.asc > $population.asc

  for beta in `seq 0.022 0.001 1.185`; do
    # Get the current job count, note the overcount due to the delay.
    # Wait if there are currently too many jobs
    while [ `qstat -u rbz5100 | grep rbz5100 | wc -l` -gt $LIMIT ]
    do
      sleep 10s
    done

    # Prepare the configuration file
    sed 's/#BETA#/'"$beta"'/g' bf-calibration.yml > bf-$population-$beta.yml
    sed -i 's/#POPULATION#/'"$population"'/g' bf-$population-$beta.yml  
 
   sed 's/#BETA#/'"$beta"'/g' template.job > bf-$population-$beta.pbs
   sed -i 's/#POPULATION#/'"$population"'/g' bf-$population-$beta.pbs  
 
    # Queue the next item
    qsub bf-$population-$beta.pbs

  done
done

