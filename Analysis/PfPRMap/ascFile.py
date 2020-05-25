# This module contains some common functions for working with ASC files.

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
