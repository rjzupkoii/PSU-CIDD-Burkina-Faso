#!/usr/bin/python3

##
# get_rasters.py
#
# This script generates mean 580Y frequency scripts based upon the 2036 (15-year)
# data set under the status quo for Burkina Faso. The script assumes that all of
# the relevant data will be under study id 9 and end with the -sq.yml filename
# suffix.
##
import csv
import os
import sys

# From the PSU-CIDD-MaSim-Support repository
sys.path.insert(1, '../../../PSU-CIDD-MaSim-Support/Python/include')
from database import select

# Connection string for the database
CONNECTION = "host=masimdb.vmhost.psu.edu dbname=burkinafaso user=sim password=sim"

# Directory to cache the replicate data in
CACHE = "data/cache"


def get_580y_frequency(replicateId):
    sql = """
    SELECT iq.location, sum(weightedoccurrences) AS weightedoccurrences
    FROM (
        SELECT mgd.location, mgd.genomeid, sum(mgd.weightedoccurrences) AS weightedoccurrences
        FROM sim.monthlydata md 
            INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id
        WHERE md.replicateid = %(replicateId)s
          AND md.dayselapsed BETWEEN 10592 AND 10927
        GROUP BY mgd.location, mgd.genomeid) iq
        INNER JOIN sim.genotype g on iq.genomeid = g.id
    WHERE g.name ~ '^.....Y..'
    GROUP BY iq.location
    """
    return select(CONNECTION, sql, {'replicateId':replicateId})


def get_infected_individuals(replicateId):
    sql = """
    SELECT msd.location, sum(infectedindividuals)
    FROM sim.monthlydata md
        INNER JOIN sim.monthlysitedata msd ON msd.monthlydataid = md.id
    WHERE md.replicateid = 25370
      AND md.dayselapsed BETWEEN 10592 AND 10927
    GROUP BY msd.location
    """
    return select(CONNECTION, sql, {'replicateId':replicateId})


def get_asc_header(replicateId):
    sql = """
    SELECT ncols, nrows, xllcorner, yllcorner, cellsize 
    FROM sim.configuration c
        INNER JOIN sim.replicate r ON r.configurationid = c.id
    WHERE r.id = %(replicateId)s
    """
    return select(CONNECTION, sql, {'replicateId':replicateId})


def get_replicates():
    sql = """
    SELECT c.filename, r.id
    FROM sim.configuration c
        INNER JOIN sim.replicate r ON r.configurationid = c.id
    WHERE c.studyid = 9
      AND c.filename LIKE '%-sq.yml'
      AND r.endtime IS NOT NULL
    ORDER BY c.filename
    """
    return select(CONNECTION, sql, None)


def prepare_asc(replicates):
    print(replicates)


def process():
    filename = None
    ids = []

    replicates = get_replicates()
    for replicate in replicates:
        ids.append(replicate[1])
        if not os.path.exists("{}/{}-580y.csv".format(CACHE, ids[-1])):
            save(get_580y_frequency(ids[-1]), "{}/{}-580y.csv".format(CACHE, ids[-1]))
            save(get_infected_individuals(ids[-1]), "{}/{}-infections.csv".format(CACHE, ids[-1]))

        # Continue if the filename has not changed
        if replicate[0] == filename: continue
        
        # Generate the ASC file if we have the ten replicates
        if filename is not None and len(ids) == 10:
            print("Preparing ASC file...")
            prepare_asc(ids)    

        # Reset the filename and replicates
        if filename is not None: ids = []
        filename = replicate[0]
        print("Loading {}...".format(filename.replace('.yml', '')))

def save(data, filename):
    with open(filename, 'w') as file:
        writer = csv.writer(file)
        for row in data:
            writer.writerow(row)


def main():
    if not os.path.exists(CACHE): os.makedirs(CACHE)
    process()


if __name__ == "__main__": 
    main()