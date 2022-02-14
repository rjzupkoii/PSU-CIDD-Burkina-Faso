#!/bin/bash

# Script to run the Burkina Faso imporation studies, this is really only needed
# the first time we run since the YAML and PBS files are created by it, after 
# that a runner based on a CSV file can be used. 
#
# Note that the calibrationLib.sh from PSU-CIDD-MaSim-Supoort is needed
source ./calibrationLib.sh

# Settings for the cluster
user='rbz5100'
replicates=0

# Replicate settings for studies
DENSITY_LIST="4.301 3.0"
IMPORTATION_LIST="3 6 9"

# Iterate over all of the key variables and create the studies
for density in $DENSITY_LIST; do
  for importation in $IMPORTATION_LIST; do

      # Prepare the files
      configuration="bfa-import-monthly-$importation-$density.yml"
      sed 's/#MONTH#/'"$month"'/g' bfa-importation-monthly-template.yml > $configuration
      sed -i 's/#PARASITEDENSITY#/'"$density"'/g' $configuration
      sed -i 's/#IMPORTATIONS#/'"$importation"'/g' $configuration

      job="bfa-import-$importation-$density.pbs"
      sed 's/#FILENAME#/'"$configuration"'/g' template.job > $job

      # Queue a single job
      check_delay $user
      qsub $job
      let "replicates+=1"
  done
done

echo "Jobs run: $replicates"