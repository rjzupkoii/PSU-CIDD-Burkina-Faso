#!/bin/bash

# Script to run the Burkina Faso seasonal immunity studies, note these are logging
# to CSV so we need to be careful to properly track the jobs

for job in `seq 1 1 50`; do
  filename="bfa-seasonal-$job.job"
  sed 's/#JOB#/'"$job"'/g' si_template.job > $filename
  qsub $filename
done