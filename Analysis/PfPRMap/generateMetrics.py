# This module contains functions relevent to getting metrics from ASC files.

from ascFile import *

[ ascheader, district ] = load_asc("../../GIS/bfa_admin.asc")
[ ascheader, pfpr ] = load_asc("../../GIS/bfa_pfpr_2to10.asc")
[ ascheader, population ] = load_asc("../../GIS/bfa_pop_2017.asc")

WEIGHTEDPFPR = 'out/weighted_pfpr.csv'

NUMERATOR = 0
DENOMINATOR = 1

data = {}
totalPopulation = 0

for row in range(ascheader['nrows']):
    for col in range(ascheader['ncols']):
        # Continue if there is no data
        if district[row][col] == ascheader['nodata']:
            continue

        # Create the district if it does not exist
        key = district[row][col]
        if not key in data.keys():
            data[key] = [0, 0]

        # Update the running values
        data[key][NUMERATOR] += pfpr[row][col] * population[row][col]
        data[key][DENOMINATOR] += population[row][col]
        totalPopulation += population[row][col]

numerator = 0
denominator = 0

with open(WEIGHTEDPFPR, 'w') as out:
    for key in data.keys():
        numerator += data[key][NUMERATOR]
        denominator += data[key][DENOMINATOR]
        result = round((data[key][NUMERATOR] / data[key][DENOMINATOR]) * 100, 2)
        message = "District: {0}, PfPR: {1}%".format(int(key), result)
        
        out.write("{},{}\n".format(int(key), result))
        print(message)

result = round(numerator * 100 / denominator, 2)
print("\nFull Map, PfPR: {0}%".format(result))

print("\nPopulation: {:,}".format(totalPopulation))

