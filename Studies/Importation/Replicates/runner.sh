#!/bin/bash

# Script to run the Burkina Faso imporation studies, this is really only needed
# the first time we run since the YAML and PBS files are created by it, after 
# that a runner based on a CSV file can be used. 
#
# Note that the calibrationLib.sh from PSU-CIDD-MaSim-Supoort is needed
source ./calibrationLib.sh

# Settings for the cluster
user='rbz5100'

# Replicate settings for studies
DENSITY_LIST="4.301 3.0"
IMPORTATION_LIST="3 6 9"
MUTATION_LIST="0 0.01983"

# Note that studies 1 and 2 are reserved for calibration and validation respectively.
study=3

# Iterate over all of the key variables and create the studies
for month in `seq 1 1 12`; do
  for density in $DENSITY_LIST; do
    for importation in $IMPORTATION_LIST; do
      for mutation in $MUTATION_LIST; do

        # Prepare the files
        file="bfa-import-$month-$importation-$density-$mutation.yml"
        sed 's/#MONTH#/'"$month"'/g' bfa-importation-template.yml > $file
        sed -i 's/#PARASITEDENSITY#/'"$density"'/g' $file
        sed -i 's/#IMPORTATIONS#/'"$importation"'/g' $file
        sed -i 's/#MUTATION#/'"$mutation"'/g' $file

        file="bfa-import-$month-$importation-$density-$mutation.pbs"
        sed 's/#FILENAME#/'"$file"'/g' template.job > $file
        sed -i 's/#STUDY#/'"$study"'/g' $file       

        # Queue a single job
        check_delay $user
        qsub $file
        let "study+=1"
      done
    done
  done
done

echo "Jobs run: $((study - 3))"