# This module contains functions relevent to getting metrics from ASC files.

from ascFile import *

[ ascheader, district ] = load_asc("../../GIS/bf_admin_raster.asc")
[ ascheader, pfpr ] = load_asc("../../GIS/bf_pfpr_raster.asc")
[ ascheader, population ] = load_asc("../../GIS/bf_pop_raster.asc")

NUMERATOR = 0
DENOMINATOR = 1

data = {}

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

numerator = 0
denominator = 0
for key in data.keys():
    numerator += data[key][NUMERATOR]
    denominator += data[key][DENOMINATOR]
    result = round((data[key][NUMERATOR] / data[key][DENOMINATOR]) * 100, 2)
    message = "District: {0}, PfPR: {1}%".format(int(key), result)
    print(message)

result = round(numerator * 100 / denominator, 2)
print("\nFull Map, PfPR: {0}%".format(result))
