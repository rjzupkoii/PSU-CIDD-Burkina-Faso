# This module reads an ASC file that contains the PfPR for the two to ten age
# bracket and generates three ASC files with beta values that represent the
# high, median, and low values.

import csv

FILENAME = '../../Data/bf-population-beta.csv'

# Read the relevent data from the CSV file into a dictionary
def load_betas():
    lookup = {}
    with open(FILENAME) as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:

            # Add a new entry for the population
            if not row['population'] in lookup:
                lookup[row['population']] = []


            # Append the beta and PfPR
            lookup[row['population']].append([ row['pfpr2to10'], row['beta'] ])
    return lookup


lookup = load_betas()
