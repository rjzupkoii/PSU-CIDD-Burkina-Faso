#!/usr/bin/python 

# reduceEpsilons.py
#
# This module takes the inputs used by createBetaMap.py as well as the epsilon
# file to prepare 

import csv

from include.ascFile import *
from include.calibrationLib import *

# TODO Migrate these to command line parameters
# The maximum epsilon value that we are comforable with
MAXIMUM = 0.01

# The step value to use to fill the gap between this beta and the next
STEP = 0.001

# TODO Figure out a better way to store these locations, maybe a library that finds them?
# Country specific inputs
CALIBRATION = 'data/calibration.csv'
POPULATIONVALUES = 'data/bfa_pop.asc'
TREATMENTVALUES = 'data/bfa_treatment.asc'
ZONEVALUES = 'data/bfa_ecozone.asc'

# Inputs from other modules
BETAVALUES = 'out/bf_mean_beta.asc'
EPSILONVALUES = 'out/bf_epsilons_beta.asc'

# Default output
RESULTS = 'out/reduction.csv'
SCRIPT = 'out/script.sh'

parameters = {}

def addBeta(lookup, zone, beta, population, treatment):
    global parameters
    
    # Determine the population and treatment bin we are working with
    populationBin = get_bin(population, lookup[zone].keys())
    treatmentBin = get_bin(treatment, lookup[zone][populationBin].keys())

    # Update the dictionary
    if zone not in parameters:
        parameters[zone] = {}
    if populationBin not in parameters[zone]:
        parameters[zone][populationBin] = {}
    if treatmentBin not in parameters[zone][populationBin]:
        parameters[zone][populationBin][treatmentBin] = set()

    # Add the stepped betas to the set
    value = round(beta - (STEP * 10), 3)
    while value < beta + (STEP * 10):
        parameters[zone][populationBin][treatmentBin].add(value)
        value = round(value + STEP, 3)
  

def getLookupBetas(lookup, zone, population, treatment):
    betas = set()
    for row in lookup[zone][population][treatment]:
        betas.add(row[1])
    return betas


def writeBetas(lookup):
    global parameters

    # Generate a list of populations to create ASC files for
    populationAsc = set()

    # Generate a list of betas to run (same format as missing.csv) that haven't been seen before
    reduced = []
    for zone in sorted(parameters.keys()):
        for population in sorted(parameters[zone].keys()):
            populationAsc.add(int(population))
            for treatment in sorted(parameters[zone][population]):
                betas = getLookupBetas(lookup, zone, population, treatment)
                for beta in sorted(parameters[zone][population][treatment]):
                    if beta not in betas: reduced.append([zone, population, treatment, beta])

    # Save the missing values as a CSV file
    print "Preparing inputs, {}".format(RESULTS)
    with open(RESULTS, "wb") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(reduced)

    print "Preparing script, {}".format(SCRIPT)
    with open(SCRIPT, "w") as script:
        script.write("#!/bin/bash\n")
        script.write("generatePopulationAsc \"\\\"")
        for value in sorted(populationAsc):
            script.write("{} ".format(value))
        script.write("\\\"\"\n")
        script.write("generateZoneAsc \"\\\"")
        for value in sorted(parameters.keys()):
            script.write("{} ".format(value))
        script.write("\\\"\"\n")
        script.write("run 'reduced.csv'\n")
        

def main():
    global parameters

    # Load the relevent data
    [ ascheader, zones ] = load_asc(ZONEVALUES)
    [ ascheader, population ] = load_asc(POPULATIONVALUES)
    [ ascheader, treatment ] = load_asc(TREATMENTVALUES)
    lookup = load_betas(CALIBRATION)

    # Read the epsilons file in
    [ ascheader, beta ] = load_asc(BETAVALUES )
    [ ascheader, epsilon ] = load_asc(EPSILONVALUES)

    print "Evaluating epsilons for {} rows, {} columns".format(ascheader['nrows'], ascheader['ncols'])

    # Scan each of the epsilons
    for row in range(0, ascheader['nrows']):
        for col in range(0, ascheader['ncols']):
            # Pass on nodata
            value = epsilon[row][col]
            if value == ascheader['nodata']: continue

            # Pass when value is less than maximum
            if value < MAXIMUM: continue

            # Update the running list
            addBeta(lookup, int(zones[row][col]), beta[row][col], population[row][col], treatment[row][col] / 100)

    # Check to see if we are done
    if len(parameters) == 0:
        print "Nothing to reduce!"
    else:
        writeBetas(lookup)


if __name__ == "__main__":
    main()