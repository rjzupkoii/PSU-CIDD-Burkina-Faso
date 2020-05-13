# This module reads an ASC file that contains the PfPR for the two to ten age
# bracket and generates three ASC files with beta values that represent the
# high, median, and low values.

import csv

# Margin used for PfPR values
MARGIN = 0.001

BETAVALUES = '../../Data/bf-population-beta.csv'
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


            # Append the beta and PfPR
            lookup[row['population']].append( \
                [ float(row['pfpr2to10']) / 100, float(row['beta']) ])
    return lookup


# Read the ASC file and return the header / data
def load_asc(filename):
    with open(filename) as ascfile:    
        lines = ascfile.readlines()

        # Read the header values
        ascheader = {}
        ascheader['ncols'] = int(lines[0].split()[1])
        ascheader['nrows'] = int(lines[1].split()[1])
        ascheader['xllcorner'] = float(lines[2].split()[1])
        ascheader['yllcorner'] = float(lines[3].split()[1])
        ascheader['cellsize'] = float(lines[4].split()[1])
        ascheader['nodata'] = int(lines[5].split()[1])

        # Read the rest of the enteries
        ascdata = []
        for ndx in range(6, ascheader['nrows'] + 6):
            row = [ float(value) for value in lines[ndx].split() ]
            ascdata.append(row)

        return [ ascheader, ascdata ]


# Write an ASC file using the data provided
def write_asc(ascheader, ascdata, filename):
    with open(filename, 'w') as ascfile:

        # Write the header values
        ascfile.write('ncols         ' + str(ascheader['ncols']) + '\n')
        ascfile.write('nrows         ' + str(ascheader['nrows']) + '\n')
        ascfile.write('xllcorner     ' + str(ascheader['xllcorner']) + '\n')
        ascfile.write('yllcorner     ' + str(ascheader['yllcorner']) + '\n')
        ascfile.write('cellsize      ' + '{0:.8g}'.format(ascheader['cellsize']) + '\n')
        ascfile.write('NODATA_value  ' + str(ascheader['nodata']) + '\n')
                
        # Write the data
        for ndx in range(0, ascheader['nrows']):
            row = [ '{0:.8g}'.format(value) for value in ascdata[ndx] ]
            row = ' '.join(row)
            ascfile.write(row)
            ascfile.write('\n')


# Get the beta values that generate the PfPR for the given popuation, with the
# given margin of error.
def get_betas(pfpr, population, lookup, margin):

    # Note the bounds
    low = pfpr - margin
    high = pfpr + margin

    # Scan the PfPR values for the popuation that are within the margin
    betas = []
    for value in lookup[str(get_bin(population))]:
        if low <= value[0] and value[0] <= high:
            betas.append(value[1])

    # Note the list size if > 1
    if len(betas) > 1: print(len(betas))

    # Return the betas collected
    return(betas)


# Get the popuation bin (200, 2000, 20000, or 200000) that the value belongs to
def get_bin(value):
    if value <= 200: return 200
    if value <= 2000: return 2000
    if value <= 20000: return 20000
    if value <= 200000: return 200000
    return 200000
    

def main():               
    # Load the relevent data
    [ ascheader, pfpr ] = load_asc(PFPRVALUES)
    [ ascheader, population ] = load_asc(POPULATIONVALUES)
    lookup = load_betas()

    # Prepare for the ASC data
    minBeta = []
    meanBeta = []
    maxBeta = []

    # Scan each of the rows 
    for row in range(0, ascheader['nrows']):

        # Append the empty rows
        minBeta.append([])
        meanBeta.append([])
        maxBeta.append([])

        # Scan each of the PfPR values    
        for col in range(0, ascheader['ncols']):

            # Append nodata and continue
            if pfpr[row][col] == ascheader['nodata']:
                minBeta[row].append(ascheader['nodata'])
                meanBeta[row].append(ascheader['nodata'])
                maxBeta[row].append(ascheader['nodata'])
                continue

            # Get the beta values
            values = get_betas(pfpr[row][col], \
                               population[row][col], lookup, MARGIN)

            # Was nothing returned?
            if len(values) == 0:
                minBeta[row].append(0)
                meanBeta[row].append(0)
                maxBeta[row].append(0)
                continue

            # Get the min, mean, and max
            minBeta[row].append(min(values))
            meanBeta[row].append(sum(values) / len(values))
            maxBeta[row].append(max(values))
            
    # Write the results
    write_asc(ascheader, minBeta, 'bf_min_beta.asc')
    write_asc(ascheader, meanBeta, 'bf_mean_beta.asc')
    write_asc(ascheader, maxBeta, 'bf_max_beta.asc')


if __name__ == "__main__":
    main()
