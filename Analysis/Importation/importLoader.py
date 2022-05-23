#!/usr/bin/python3

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
import re
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
			CASE WHEN strpos(c.filename, '-monthly-') > 0 THEN 0
			  ELSE cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[1] AS integer) END AS month,
			CASE WHEN strpos(c.filename, '-monthly-') > 0 
			  THEN cast((regexp_match(c.filename, '-([\d.]*)-(\d.\d*)'))[1] AS integer)
			  ELSE cast((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[2] AS integer) END AS imports,
			CASE WHEN strpos(c.filename, '-monthly-') > 0		
			  THEN CASE WHEN ((regexp_match(c.filename, '-([\d.]*)-(\d.\d*)'))[2] = '3.0') THEN 0 ELSE 1 END 
              ELSE CASE WHEN ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[3] = '3.0') THEN 0 ELSE 1 END END AS symptomatic,
			CASE WHEN strpos(c.filename, '-monthly-') > 0 THEN 0			
              ELSE CASE WHEN ((regexp_match(c.filename, '-(\d*)-(\d)-([\d.]*)-(\d.\d*)'))[4] = '0.') THEN 0 ELSE 1 END END AS mutations,
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
    importation_study()
    seasonal_study()


def importation_study():
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
            try:
                df = pd.read_csv(filename, header=None)
                if row[2] == len(df[0].unique()): continue
            except pd.errors.EmptyDataError:
                # If the file is empty then continue on to querying for the data
                pass
            
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
    if os.path.exists(MERGED): os.remove(MERGED)
    with open(MERGED, "wb") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(HEADER)
        for file in glob.glob("data/bfa-importation-*.csv"):
            with open(file) as infile:
                csvfile.write(infile.read())


def seasonal_study():
    print("Generating seasonal data files...")
    for item in os.scandir("data"):
        if not item.is_dir(): continue
        
        print("Parsing {}...".format(item.name))
        output = "intermediate/{}.csv".format(item.name)
        if os.path.exists(output):
            os.remove(output)
        header = True
        for file in os.scandir(item):
            append_seasonal_data(file, output, header)
            header = False


def append_seasonal_data(file, output, header):
    # Load the data, delete the last (superfluous) column
    data = pd.read_csv(file, header=0)
    data = data.iloc[:, :-1]

    # Delete the unused columns from the data
    del data['InfectedIndividuals']
    del data['ClinicalIndividuals']
    del data['NewInfections']
    del data['NonTreatment']
    del data['TreatmentFailure']
    
    # Add the index column
    id = re.search('(\d{1,2})', file.name).group(0)
    data.insert(0, 'ID', id)

    # Append the data to output file
    data.to_csv(output, mode='a', index=False, header=header)


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