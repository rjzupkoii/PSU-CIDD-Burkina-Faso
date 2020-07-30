# findMissing.py
#
# This script finds the combination that are missing from a calibration.

import csv

BETAVALUES = 'data/calibration.csv'
RESULTS = 'out/missing.csv'


def main():
    # Prepare our data structures
    population = set()
    treatment = set()
    beta = set()
    raw = []

    # Start by reading the raw population, treatment rate, and beta
    with open(BETAVALUES) as csvfile:
        reader = csv.DictReader(csvfile)
        raw = []
        for row in reader:
            population.add(row['population'])
            treatment.add(row['access'])
            beta.add(row['beta'])
            raw.append([row['population'], row['access'], row['beta']])

    # Unique values are loaded, sort them
    population = sorted(population, reverse=True)
    treatment = sorted(treatment)
    beta = sorted(beta)

    # Print how many we expect to find
    print "{} combinations expected".format(len(population) * len(treatment) * len(beta))

    # Scan for the matching row, add it to the missing list if not found
    missing = []
    for ndx in population:
        for ndy in treatment:
            for ndz in beta:
                row = [ndx, ndy, ndz]
                matched = False
                for index in range(0, len(raw) - 1):
                    if row == raw[index]:
                        matched = True
                if not matched:
                    missing.append(row)
    
    # Print the number missing
    print "{} combinations missing".format(len(missing))
    if len(missing) == 0: return

    # Save the missing values as a CSV file
    print "Saving {}".format(RESULTS)
    with open(RESULTS, "wb") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(missing)


if __name__ == "__main__":
    main()