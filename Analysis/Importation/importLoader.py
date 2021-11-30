#!/usr/bin/python

##
# importLoader.py
#
# This Python script pulls the relevent importation study data from the server.
##
import csv
import glob
import os
import pandas as pd
import psycopg2
import sys

sys.path.insert(1, '../Loader')
from utility import progressBar


# Connection string for the database
CONNECTION = "host=masimdb.vmhost.psu.edu dbname=burkinafaso user=sim password=sim"

# Header to use for the merged CSV file
HEADER = ["replicateid","month","imports","symptomatic","mutations","dayselapsed","infectedindividuals","clinicalepisodes","clinicaloccurrences","weightedoccurrences"]

# Filename and path fo the merged CSV file
MERGED = "data/bfa-merged.csv"


def get_configurations():
    sql = """
        SELECT configurationid, replicates = target as done, cast(replicates as int) as replicates
        FROM v_importation_replicates"""
    return select(sql, {})


def get_replicates(configurationId):
    sql = """
        SELECT sd.replicateid,
            cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[1] AS integer) AS month,
            cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[2] AS integer) AS imports,
            CASE WHEN ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[3] = '3.0') THEN 0 ELSE 1 END AS symptomatic,
            CASE WHEN ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[4] = '0.') THEN 0 ELSE 1 END AS mutations,
            sd.dayselapsed, 
            infectedindividuals, 
            clinicalepisodes, 
            CASE WHEN gd.clinicaloccurrences IS NULL THEN 0 ELSE gd.clinicaloccurrences END AS clinicaloccurrences,
            CASE WHEN gd.weightedoccurrences IS NULL THEN 0 ELSE gd.weightedoccurrences END AS weightedoccurrences
        FROM (
            SELECT md.replicateid, md.dayselapsed, 
                sum(msd.infectedindividuals) AS infectedindividuals, 
                sum(msd.clinicalepisodes) AS clinicalepisodes
            FROM sim.replicate r
                INNER JOIN sim.monthlydata md ON md.replicateid = r.id
                INNER JOIN sim.monthlysitedata msd ON msd.monthlydataid = md.id
            WHERE r.configurationid = %(configurationId)s
                and md.dayselapsed > (11 * 365)
            GROUP BY md.replicateid, md.dayselapsed) sd
        left join (
            SELECT md.replicateid, md.dayselapsed, 
                sum(mgd.clinicaloccurrences) AS clinicaloccurrences,
                sum(mgd.weightedoccurrences) AS weightedoccurrences
            FROM sim.replicate r
                INNER JOIN sim.monthlydata md ON md.replicateid = r.id
                INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id
                INNER JOIN sim.genotype g ON g.id = mgd.genomeid
            WHERE r.configurationid = %(configurationId)s
                and md.dayselapsed > (11 * 365)
                and g.name ~ '^.....Y..'
            GROUP BY md.replicateid, md.dayselapsed) gd ON (gd.replicateid = sd.replicateid and gd.dayselapsed = sd.dayselapsed)
        INNER JOIN sim.replicate r ON r.id = sd.replicateid
        INNER JOIN sim.configuration c ON c.id = r.configurationid
        WHERE r.endtime is NOT NULL
        ORDER BY replicateid, dayselapsed"""
    return select(sql, {'configurationId':configurationId})


def main():
    if not os.path.exists("data"): os.makedirs("data")

    print("Querying for configuration list...")
    configurations = get_configurations()
    
    print("Processing configuration list...")
    count = 0
    progressBar(count, len(configurations))
    for row in configurations:
        # Query for the data if we don't have have the complete data
        filename = "data/bfa-importation-{}.csv".format(row[0])

        # Don't update when we have all the records
        if os.path.exists(filename) and row[1]:
            df = pd.read_csv(filename, header=None)
            if row[2] == len(df[0].unique()): continue

        # Query and update the record
        data = get_replicates(row[0])
        with open(filename, "wb") as csvfile:
            writer = csv.writer(csvfile)
            for row in data:
                writer.writerow(list(row))

        # Note the progress
        count = count + 1
        progressBar(count, len(configurations))
        
    # Print the final 100% progress bar
    progressBar(len(configurations), len(configurations))

    print("Merging files...")
    os.remove(MERGED)
    with open(MERGED, "wb") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(HEADER)
        for file in glob.glob("data/*.csv"):
            with open(file) as infile:
                csvfile.write(infile.read())


def select(sql, parameters):
    # Open the connection
    connection = psycopg2.connect(CONNECTION)
    cursor = connection.cursor()

    # Execute the query, note the rows
    cursor.execute(sql, parameters)
    rows = cursor.fetchall()

    # Clean-up and return
    cursor.close()
    connection.close()
    return rows    


if __name__ == '__main__':
    main()