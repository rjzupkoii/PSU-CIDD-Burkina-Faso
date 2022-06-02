#!/usr/bin/env python3

# bfa_importation_odds.py
#
# Use Monte Carlo methods to generate a probability surface of importations based
# upon the population raster provided.
import random
import sys

# From the PSU-CIDD-MaSim-Support repository
sys.path.insert(1, '../../../PSU-CIDD-MaSim-Support/Python/include')
from ascFile import *

# This function is based upon ImportationPeriodicallyRandomEvent::get_location() 
# in the simulation, but is slightly simplified since the raster does not have
# age classes to be parsed nor is the population size changing over time.
def get_location(header, raster, population):
    target = random.uniform(1, population)
    for row in range(0, header['nrows']):
        for col in range(0, header['ncols']):
            if raster[row][col] == header['nodata']:
                continue
            if target < raster[row][col]:
                return row, col
            target -= raster[row][col]
    
    # We should never get here, throw an error
    raise RuntimeError('get_location completed without a location being found')


def monte_carlo(header, raster, trials):
    # Precompute the rows and columns
    rows = range(0, header['nrows'])
    cols = range(0, header['ncols'])

    # Sum the total population and build our initial results matrix
    population = 0
    results = [[0 for cols in cols] for row in rows]
    for row in rows:
        for col in cols:
            if raster[row][col] == header['nodata']:
                results[row][col] = header['nodata']
                continue
            population += int(raster[row][col])

    # Conduct the trials
    for ndx in range(trials):
        row, col = get_location(header, raster, population)
        results[row][col] += 1

    # Divide by the number of trials and return the results
    for row in rows:
        for col in cols:
            if results[row][col] == header['nodata']:
                continue
            results[row][col] = float(results[row][col]) / float(trials)
    return results


# Run the Monte Carlo for 1M iterations
if __name__ == '__main__':
    header, raster = load_asc('../../GIS/bfa_population.asc')
    results = monte_carlo(header, raster, 1000000)
    write_asc(header, results, 'out.asc')