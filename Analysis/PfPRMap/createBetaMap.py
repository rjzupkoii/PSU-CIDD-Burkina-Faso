# This module reads an ASC file that contains the PfPR for the two to ten age
# bracket and generates three ASC files with beta values that represent the
# high, median, and low values.

import csv

from ascFile import *

# Starting epsilon and delta to be used
EPSILON = 0.00001
MAX_EPSILON = 1.0

# Population adjustment to apply
POP_ADJUSTMENT = 0.2766

BETAVALUES = '../../Data/bf-population-jenks-beta.csv'
PFPRVALUES = '../../GIS/bf_pfpr_raster.asc'
POPULATIONVALUES = '../../GIS/bf_pop_raster.asc'

# Read the relevent data from the CSV file into a dictionary
def load_betas():
    lookup = {}
    with open(BETAVALUES) as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:

            # Add a new entry for the population
            if not row['population'] in lookup:
                lookup[row['population']] = []

            # Ignore the zeros
            if float(row['pfpr2to10']) == 0:
                continue

            # Append the beta and PfPR
            lookup[row['population']].append( \
                [ float(row['pfpr2to10']) / 100, float(row['beta']) ])
            
    return lookup

# Get the beta values that generate the PfPR for the given popuation, this
# function will start with the lowest epsilon value and increase it until
# at least one value is found to be returned
def get_betas(pfpr, population, lookup):
    # Inital values
    epsilon = 0
    betas = []

    # Increase the epsilon until at least one value is found
    while len(betas) == 0:
        epsilon += EPSILON
        betas = get_betas_scan(pfpr, population, lookup, epsilon)

        # Prevent an infinite loop, will result in an error
        if epsilon == MAX_EPSILON:
            print('Match not found!\nPfPR: ', pfpr, 'Population: ', population)
            return [None, None]

    # Return the results
    return [betas, epsilon] 


# Get the beta values that generate the PfPR for the given popuation, with the
# given margin of error.
def get_betas_scan(pfpr, population, lookup, epsilon):

    # Note the bounds
    low = pfpr - epsilon
    high = pfpr + epsilon

    # Scan the PfPR values for the popuation that are within the margin
    betas = []
    for value in lookup[str(get_bin(population, lookup.keys()))]:
        # Add the value if it is in the bounds
        if low <= value[0] and value[0] <= high:
            betas.append(value[1])

        # We assume the data is stored, so break once the high value is less
        # than the current PfPR
        if high < value[0]: break

    # Note the list size if > 1
    if len(betas) > 1: print(len(betas))

    # Return the betas collected
    return(betas)


# Get the popuation bin that the value belongs to
def get_bin(value, bins):
    # Sort the bins and step through them
    bins.sort()
    for item in bins:
        if value < item:
            return item

    # For values greater than the largest bin, return that one
    if item >= max(bins):
        return max(bins)

    # Throw an error if we coudln't find a match (shouldn't happen)
    raise Exception("Matching bin not found for value: " + str(value))
    

def main():               
    # Load the relevent data
    [ ascheader, pfpr ] = load_asc(PFPRVALUES)
    [ ascheader, population ] = load_asc(POPULATIONVALUES)
    lookup = load_betas()

    # Prepare for the ASC data
    epsilons = []
    minBeta = []
    meanBeta = []
    maxBeta = []
    adjusted = []

    # Scan each of the rows 
    for row in range(0, ascheader['nrows']):

        # Append the empty rows
        epsilons.append([])
        minBeta.append([])
        meanBeta.append([])
        maxBeta.append([])
        adjusted.append([])

        # Scan each of the PfPR values    
        for col in range(0, ascheader['ncols']):

            # Append nodata and continue
            if pfpr[row][col] == ascheader['nodata']:
                epsilons[row].append(ascheader['nodata'])
                minBeta[row].append(ascheader['nodata'])
                meanBeta[row].append(ascheader['nodata'])
                maxBeta[row].append(ascheader['nodata'])
                adjusted[row].append(ascheader['nodata'])
                continue

            # Get the beta values
            [values, epsilon] = get_betas( \
                pfpr[row][col], population[row][col], lookup)

            # Was nothing returned?
            if len(values) == 0:
                epsilons[row].append(0)
                minBeta[row].append(0)
                meanBeta[row].append(0)
                maxBeta[row].append(0)
                adjusted[row].append(0)
                continue

            # Note the epsilon
            epsilons[row].append(epsilon)

            # Get the min, mean, and max
            minBeta[row].append(min(values))
            meanBeta[row].append(sum(values) / len(values))
            maxBeta[row].append(max(values))

            # Adjust the value from untreated to treated
            beta = min(values)
            diff = (-1.24 * pow(beta, 2) + 4.88 * beta + 2.13) / 100
            [values, epsilon] = get_betas(pfpr[row][col] - diff, population[row][col], lookup)
            adjusted[row].append(min(values))            

            # Note the progress
            print(row, col)
            
    # Write the results
    write_asc(ascheader, epsilons, 'out/bf_epsilons_beta.asc')
    write_asc(ascheader, minBeta, 'out/bf_min_beta.asc')
    write_asc(ascheader, meanBeta, 'out/bf_mean_beta.asc')
    write_asc(ascheader, maxBeta, 'out/bf_max_beta.asc')
    write_asc(ascheader, adjusted, 'out/bf_adjusted_beta.asc')


if __name__ == "__main__":
    main()
