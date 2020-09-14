#!/usr/bin/python

##
# loader.py
#
# This script pulls the relevent study data from the server.
##
import csv
import glob
import os
import psycopg2
import sys

from utility import *


CONNECTION = "host=masimdb.vmhost.psu.edu dbname=burkinafaso user=sim password=sim"

# Indices in getReplicates query
REPLICATEID = 4


# Check to see if data exists for the given replicate after the burn-in period
def checkGetFrequency(replicateId, startDay):
    sql = """
        SELECT exists(SELECT 1 FROM sim.monthlydata md
            INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id
            INNER JOIN sim.location l ON l.id = mgd.locationid
            INNER JOIN sim.genotype g ON g.id = mgd.genomeid
        WHERE md.replicateid = %(replicateId)s AND md.dayselapsed > %(startDay)s 
          AND g.name ~ '^.....Y..'
        )"""
    
    # Open the connection
    connection = psycopg2.connect(CONNECTION)
    cursor = connection.cursor()

    # Execute the query, note the rows
    cursor.execute(sql, {'replicateId':replicateId, 'startDay':startDay})
    result = cursor.fetchone()

    # Clean-up and return
    cursor.close()
    connection.close()
    return result[0]


# Return the frequency data for each cell after the burn-in period is complete
def getFrequency(replicateId, startDay):
    sql = """
        SELECT dayselapsed, l.x, l.y, sum(mgd.weightedfrequency) AS resistancefrequency
        FROM sim.monthlydata md
            INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id
            INNER JOIN sim.location l ON l.id = mgd.locationid
            INNER JOIN sim.genotype g ON g.id = mgd.genomeid
        WHERE md.replicateid = %(replicateId)s  AND md.dayselapsed > %(startDay)s
          AND g.name ~ '^.....Y..'
        GROUP BY dayselapsed, x, y"""
    return select(sql, {'replicateId':replicateId, 'startDay':startDay})


# Return all of the replicates and their rate associated with the given study
def getReplicates(studyId):
    sql = """
        SELECT cast((regexp_matches(filename, '^(\d\.\d*)-bfa\.yml'))[1] as float) AS rate, 
            nrows, ncols, c.id AS configurationid, r.id AS replicateid,
            CASE WHEN r.endtime IS NULL THEN 0 ELSE 1 END As complete
        FROM sim.configuration c INNER JOIN sim.replicate r ON r.configurationid = c.id
        WHERE c.studyid = %(studyId)s ORDER BY rate"""
    return select(sql, {'studyId':studyId})


# Get the summary data for the given replicate after the burn-in period is complete
def getSummary(replicateId, startDay):
    sql = """
        SELECT md.dayselapsed,
            l.district,
            SUM(mgd.occurrences) AS occurrences, 
            SUM(mgd.clinicaloccurrences) AS clinicaloccurrrences, 
            SUM(mgd.weightedfrequency) / COUNT(mgd.weightedfrequency) AS meanweightedfrequency
        FROM sim.monthlydata md
            INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id
            INNER JOIN sim.location l on l.id = mgd.locationid
            INNER JOIN sim.genotype g ON g.id = mgd.genomeid
        WHERE md.replicateid = %(replicateId)s  AND md.dayselapsed > %(startDay)s
          AND g.name ~ '^.....Y..'
        GROUP BY md.dayselapsed, district"""
    return select(sql, {'replicateId':replicateId, 'startDay':startDay})


# Process the frequency data by aggregating it together across all cells and replicates for each rate
def processFrequencies(replicates, burnIn):
    # Update the user and note common data
    print("Processing {} replicate frequencies...".format(len(replicates)))
    nrows = replicates[0][1]
    ncols = replicates[0][2]
    
    # Note the progress
    total = 0
    progressBar(total, len(replicates) + 1)

    # Iterate through all of the rows
    currentRate = None
    for replicate in replicates:

        # Reset the replicate count on a new row
        if currentRate != replicate[0]:
            if currentRate is not None: 
                saveFrequencies(data, currentRate)
                del data
            replicateCount = 0
            currentRate = replicate[0]
            data = {}

        # Run a short query to see if we have anything to work with
        if checkGetFrequency(replicate[REPLICATEID], burnIn):
            for row in getFrequency(replicate[REPLICATEID], burnIn):
                days = row[0]
                if days not in data: data[days] = [[[] for _ in range(nrows)] for _ in range(ncols)]
                c = row[1]
                r = row[2]
                data[days][r][c].append(row[3])

        # Note the progress
        total = total + 1
        progressBar(total, len(replicates) + 1)

    # Save the last data set
    saveFrequencies(data, currentRate)
    progressBar(total + 1, len(replicates) + 1) 


# Process the summary data by appending it for each complete replicate and day
def processSummaries(replicates, burnIn):
    # Update the user
    print("Processing {} replicate frequencies...".format(len(replicates)))

    # Note the progress
    total = 0
    progressBar(total, len(replicates) + 1)

    # Iterate through all of the rows
    for replicate in replicates:

        # Load and save the data
        data = getSummary(replicate[REPLICATEID], burnIn)
        saveSummary(data, replicate[0], replicate[REPLICATEID])
        
        # Note the progress
        total = total + 1
        progressBar(total, len(replicates) + 1)

    # Save the last data set
    progressBar(total + 1, len(replicates) + 1) 


def saveFrequencies(data, rate):
    with open("out/{}-frequency-map.csv".format(rate), "wb") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["days", "row", "col", "frequency"])

        for day in sorted(data.keys()):
            for row in range(len(data[day])):
                for col in range(len(data[day][row])):
                    if len(data[day][row][col]) == 0: continue
                    # Save the average of the frequencies recorded
                    frequency = sum(data[day][row][col]) / len(data[day][row][col])
                    writer.writerow([day, row, col, frequency])


def saveSummary(data, rate, replicateId):
    filename = "out/{}-summary-data.csv".format(rate)
    exists = os.path.exists(filename)
    with open(filename, "ab") as csvfile:
        writer = csv.writer(csvfile)
        if not exists: writer.writerow(["replicateId", "days", "district", "occurrences", "clinicaloccurrrences", "meanweightedfrequency"])
        for row in data:
            data = [replicateId] + list(row)
            writer.writerow(data)


def main(studyId, burnIn):
    # Get the configurations, replicates, and do some bookkeeping
    replicates = getReplicates(studyId)
    if len(replicates) == 0:
        print("No replicates to process!")
        return

    # Run the functions
#    processFrequencies(replicates, burnIn)
    processSummaries(replicates, burnIn)


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
    if len(sys.argv) != 3:
        print "Usage: ./loader.py [studyId] [startDay]"
        print "studyId - database id of the study"
        print "startDay - the first model day to start processing data for"
        exit(0)

    # Parse the parameters
    studyId = int(sys.argv[1])
    startDay = int(sys.argv[2])

    # Prepare the environment
    if not os.path.exists("out"): 
        os.makedirs("out")
    else:
        for filename in glob.glob("out/*summary*.csv"): os.remove(filename)

    main(studyId, startDay)

