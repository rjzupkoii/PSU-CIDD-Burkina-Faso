#!/bin/bash

# This script will queue processes on the cluster up to the configured limit based upon the 
# combinations that appear in a CSV file. The filenames will encode the values based using
# the name POPUATION-ACCESS-BETA-bfa.yml although a fixed study id is in place as well.

FILENAME='missing.csv'
LIMIT=100

while IFS=, read -r population access beta
do
    echo "Values $population, $access, $beta"

    # Get the current job count, note the overcount due to the delay.
    # Wait if there are currently too many jobs
    while [ `qstat -u rbz5100 | grep rbz5100 | wc -l` -gt $LIMIT ]
    do
        sleep 10s
    done

    # Trim the return
    beta="$(echo "$beta"|tr -d '\r')"

    # Prepare the configuration file
    sed 's/#BETA#/'"$beta"'/g' bf-calibration.yml > $population-$access-$beta-bfa.yml
    sed -i 's/#POPULATION#/'"$population"'/g' $population-$access-$beta-bfa.yml  
    sed -i 's/#ACCESS#/'"$access"'/g' $population-$access-$beta-bfa.yml

    sed 's/#BETA#/'"$beta"'/g' template.job > $population-$access-$beta-bfa.pbs
    sed -i 's/#POPULATION#/'"$population"'/g' $population-$access-$beta-bfa.pbs
    sed -i 's/#ACCESS#/'"$access"'/g' $population-$access-$beta-bfa.pbs

    # Queue the next item
    qsub $population-$access-$beta-bfa.pbs

done < $FILENAME