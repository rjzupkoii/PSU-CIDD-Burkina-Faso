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


# Return the components of the frequency data for each cell after the burn-in period is complete
def getFrequencySubset(replicateId, subset):
    sql = """   
        SELECT md.dayselapsed, l.x, l.y, msd.infectedindividuals,
            SUM(CASE WHEN g.name ~ '^.....Y..' THEN mgd.clinicaloccurrences ELSE 0 END) AS clinicaloccurrences,
            SUM(CASE WHEN g.name ~ '^.....Y..' THEN mgd.weightedoccurrences ELSE 0 END) AS weightedoccurrences
        FROM sim.monthlydata md
            INNER JOIN sim.monthlysitedata msd ON msd.monthlydataid = md.id
            INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id AND msd.locationid = mgd.locationid
            INNER JOIN sim.genotype g ON g.id = mgd.genomeid
            INNER JOIN sim.location l ON l.id = msd.locationid
        WHERE md.replicateid = %(replicateId)s AND md.dayselapsed in ({})
        GROUP BY md.dayselapsed, l.x, l.y, msd.infectedindividuals""".format(subset)
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
        SELECT md.dayselapsed, l.district,
            SUM(msd.infectedindividuals) as infectedindividuals,
            SUM(CASE WHEN g.name ~ '^.....Y..' THEN mgd.occurrences ELSE 0 END) as occurrences,
            SUM(CASE WHEN g.name ~ '^.....Y..' THEN mgd.clinicaloccurrences ELSE 0 END) AS clinicaloccurrrences,
            SUM(CASE WHEN g.name ~ '^.....Y..' THEN mgd.weightedoccurrences ELSE 0 END) AS weightedoccurrences
        FROM sim.monthlydata md
            INNER JOIN sim.monthlysitedata msd ON msd.monthlydataid = md.id
            INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id AND msd.locationid = mgd.locationid
            INNER JOIN sim.genotype g ON g.id = mgd.genomeid
            INNER JOIN sim.location l ON l.id = msd.locationid
        WHERE md.replicateid = %(replicateId)s  AND md.dayselapsed > %(startDay)s
        GROUP BY md.dayselapsed, district"""
    return select(sql, {'replicateId':replicateId, 'startDay':startDay})


# Process the frequency data by aggregating it together across all cells and replicates for each rate
def processFrequencies(replicates, subset):
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
        for row in getFrequencySubset(replicate[REPLICATEID], subset):
            days = row[0]
            if days not in data: data[days] = [[[0, 0, 0] for _ in range(nrows)] for _ in range(ncols)]
            c = row[1]
            r = row[2]

            # Array formatted as: 0 - infectedindividuals (query index 3)
            #                     1 - weightedoccurrences (query index 5)
            #                     3 - count
            data[days][r][c][0] += row[3]
            data[days][r][c][1] += row[5]
            data[days][r][c][2] += 1

        # Note the progress
        total = total + 1
        progressBar(total, len(replicates) + 1)

    # Save the last data set
    saveFrequencies(data, currentRate)
    progressBar(total + 1, len(replicates) + 1) 


# Process the summary data by appending it for each complete replicate and day
def processSummaries(replicates, burnIn):
    # Update the user
    print("Processing {} replicate summaries...".format(len(replicates)))

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

                    # Array formatted as: 0 - infectedindividuals (query index 3)
                    #                     1 - weightedoccurrences (query index 5)
                    #                     3 - count

                    # If the count is still zero, press on
                    count = data[day][row][col][2]
                    if count == 0: continue

                    infectedindividuals = data[day][row][col][0]
                    weightedoccurrences = data[day][row][col][1]                   

                    # Save the average of the frequencies recorded
                    frequency = (weightedoccurrences / count) / (infectedindividuals / count)
                    writer.writerow([day, row, col, frequency])


def saveSummary(data, rate, replicateId):
    filename = "out/{}-summary-data.csv".format(rate)
    exists = os.path.exists(filename)
    with open(filename, "ab") as csvfile:
        writer = csv.writer(csvfile)
        if not exists: writer.writerow(["replicateId", "days", "district", "infectedindividuals", "occurrences", "clinicaloccurrrences", "weightedoccurrences"])
        for row in data:
            data = [replicateId] + list(row)
            writer.writerow(data)


def main(studyId, burnIn, subset):
    # Get the configurations, replicates, and do some bookkeeping
    replicates = getReplicates(studyId)
    if len(replicates) == 0:
        print("No replicates to process!")
        return

    # Run the functions
    processFrequencies(replicates, subset)
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

    # TODO Find a better way of getting the subset
    main(studyId, startDay, "5114, 6940, 8766, 10950")

