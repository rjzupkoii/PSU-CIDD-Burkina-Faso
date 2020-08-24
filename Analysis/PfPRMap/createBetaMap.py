#!/usr/bin/python

# createBetaMap.py
#
# This module reads an ASC file that contains the PfPR for the two to ten age
# bracket and generates three ASC files with beta values.

import csv

from include.ascFile import *
from include.utility import *

# Starting epsilon and delta to be used
EPSILON = 0.00001
MAX_EPSILON = 0.25

BETAVALUES = 'data/calibration.csv'

PFPRVALUES = 'data/bfa_pfpr_2to10.asc'
POPULATIONVALUES = 'data/bfa_pop.asc'
TREATMENTVALUES = 'data/bfa_treatment.asc'
ZONEVALUES = 'data/bfa_ecozone.asc'

# Read the relevent data from the CSV file into a dictionary
def load_betas():
    lookup = {}
    with open(BETAVALUES) as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:

            # Add a new entry for the zone
            zone = int(row['zone'])
            if not zone in lookup:
                lookup[zone] = {}

            # Add a new entry for the population
            population = float(row['population'])
            if not population in lookup[zone]:
                lookup[zone][population] = {}
            
            # Add a new entry for the treatment
            treatment = float(row['access'])
            if not treatment in lookup[zone][population]:
                lookup[zone][population][treatment] = []

            # Ignore the zeros
            if float(row['pfpr2to10']) == 0: continue

            # Append the beta and PfPR
            lookup[zone][population][treatment].append([ float(row['pfpr']) / 100, float(row['beta']) ])

    return lookup

# Get the beta values that generate the PfPR for the given population and 
# treatment level, this function will start with the lowest epsilon value 
# and increase it until at least one value is found to be returned
def get_betas(zone, pfpr, population, treatment, lookup):
    # Inital values
    epsilon = 0
    betas = []

    # Increase the epsilon until at least one value is found
    while len(betas) == 0:
        epsilon += EPSILON
        betas = get_betas_scan(zone, pfpr, population, treatment, lookup, epsilon)

        # Prevent an infinite loop, will result in an error
        if epsilon == MAX_EPSILON:
            print('Match not found!\nPfPR: ', pfpr, 'Population: ', population)
            return [None, None]

    # Return the results
    return [betas, epsilon] 


# Get the beta values that generate the PfPR for the given population and 
# treatment level, within the given margin of error.
def get_betas_scan(zone, pfpr, population, treatment, lookup, epsilon):

    # The zone is a bin, so it should just be there
    if not zone in lookup:
        raise ValueError("Zone {} was not found in lookup".format(zone))

    # Determine the population and treatment bin we are working with
    populationBin = get_bin(population, lookup[zone].keys())
    treatmentBin = get_bin(treatment, lookup[zone][populationBin].keys())
    
    # Note the bounds
    low = pfpr - epsilon
    high = pfpr + epsilon

    # Scan the PfPR values for the population and treatment level that are 
    # within the margin
    betas = []
    for value in lookup[zone][populationBin][treatmentBin]:
            
        # Add the value if it is in the bounds
        if low <= value[0] and value[0] <= high:
            betas.append(value[1])
            
        # We assume the data is stored, so break once the high value is less
        # than the current PfPR
        if high < value[0]: break

    # Return the betas collected
    return(betas)


# Get the bin that the value belongs to
def get_bin(value, bins):
    # Sort the bins and step through them
    bins.sort()
    for item in bins:
        if value < item:
            return item

    # For values greater than the largest bin, return that one
    if item >= max(bins):
        return max(bins)

    # Throw an error if we couldn't find a match (shouldn't happen)
    raise Exception("Matching bin not found for value: " + str(value))
    

def main():               
    # Load the relevent data
    [ ascheader, zones ] = load_asc(ZONEVALUES)
    [ ascheader, pfpr ] = load_asc(PFPRVALUES)
    [ ascheader, population ] = load_asc(POPULATIONVALUES)
    [ ascheader, treatment ] = load_asc(TREATMENTVALUES)
    lookup = load_betas()

    # Prepare for the ASC data
    epsilons = []
    meanBeta = []

    print "Determining betas for {} rows, {} columns".format(ascheader['nrows'], ascheader['ncols'])

    # Scan each of the rows 
    for row in range(0, ascheader['nrows']):

        # Append the empty rows
        epsilons.append([])
        meanBeta.append([])

        # Scan each of the PfPR values    
        for col in range(0, ascheader['ncols']):

            # Append nodata and continue
            if pfpr[row][col] == ascheader['nodata']:
                epsilons[row].append(ascheader['nodata'])
                meanBeta[row].append(ascheader['nodata'])
                continue

            # Get the beta values
            [values, epsilon] = get_betas( \
                zones[row][col], pfpr[row][col], population[row][col], treatment[row][col] / 100, lookup)

            # Was nothing returned?
            if len(values) == 0:
                epsilons[row].append(0)
                meanBeta[row].append(0)
                continue

            # Note the epsilon and the mean
            epsilons[row].append(epsilon)
            meanBeta[row].append(sum(values) / len(values))

        # Note the progress
        progressBar(row + 1, ascheader['nrows'])
                
    # Write the results
    print "Saving {}".format('out/bf_epsilons_beta.asc')
    write_asc(ascheader, epsilons, 'out/bf_epsilons_beta.asc')
    print "Saving {}".format('out/bf_mean_beta.asc')
    write_asc(ascheader, meanBeta, 'out/bf_mean_beta.asc')


if __name__ == "__main__":
    main()
