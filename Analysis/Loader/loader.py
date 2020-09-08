#!/usr/bin/python

##
# loader.py
#
# This script pulls the relevent study data from the server.
##
import csv
import os
import psycopg2
import sys

from utility import *


CONNECTION = "host=masimdb.vmhost.psu.edu dbname=burkinafaso user=sim password=sim"


# Check to see if data exists for the given replicate after the burn-in period
def checkGetFrequency(replicateId, startDay):
    #  AND g.name ~ '^.....Y..'
    sql = """
        SELECT exists(SELECT 1 FROM sim.monthlydata md
            INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id
            INNER JOIN sim.location l ON l.id = mgd.locationid
            INNER JOIN sim.genotype g ON g.id = mgd.genomeid
        WHERE md.replicateid = %(replicateId)s AND md.dayselapsed > %(startDay)s
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
    # AND g.name ~ '^.....Y..'
    sql = """
        SELECT dayselapsed, l.x, l.y, sum(mgd.weightedfrequency) AS resistancefrequency
        FROM sim.monthlydata md
            INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id
            INNER JOIN sim.location l ON l.id = mgd.locationid
            INNER JOIN sim.genotype g ON g.id = mgd.genomeid
        WHERE md.replicateid = %(replicateId)s  AND md.dayselapsed > %(startDay)s
        GROUP BY dayselapsed, x, y"""

    # Open the connection
    connection = psycopg2.connect(CONNECTION)
    cursor = connection.cursor()

    # Execute the query, note the rows
    cursor.execute(sql, {'replicateId':replicateId, 'startDay':startDay})
    rows = cursor.fetchall()

    # Clean-up and return
    cursor.close()
    connection.close()
    return rows


def getReplicates(studyId):
    sql = """
        SELECT cast((regexp_matches(filename, '^(\d\.\d*)-bfa\.yml'))[1] as float) AS rate, 
            nrows, ncols,
            c.id AS configurationid, r.id AS replicateid
        FROM sim.configuration c INNER JOIN sim.replicate r ON r.configurationid = c.id
        WHERE c.studyid = %(studyid)s ORDER BY rate"""

    # Open the connection
    connection = psycopg2.connect(CONNECTION)
    cursor = connection.cursor()

    # Execute the query, note the rows
    cursor.execute(sql, {'studyid':studyId})
    rows = cursor.fetchall()

    # Clean-up and return
    cursor.close()
    connection.close()
    return rows


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


def main(studyId, burnIn):
    # Get the configurations, replicates, and do some bookkeeping
    replicates = getReplicates(studyId)
    if len(replicates) == 0:
        print("No replicates to process!")
        return

    # Update the user and note common data
    print("Processing {} replicates...".format(len(replicates)))
    nrows = replicates[0][1]
    ncols = replicates[0][2]
    
    # Note the progress
    total = 0
    progressBar(total, len(replicates))

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
        if checkGetFrequency(replicate[4], burnIn):
            for row in getFrequency(replicate[4], burnIn):
                days = row[0]
                if days not in data: data[days] = [[[] for _ in range(nrows)] for _ in range(ncols)]
                c = row[1]
                r = row[2]
                data[days][r][c].append(row[3])

        # Note the progress
        total = total + 1
        progressBar(total, len(replicates))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print "Usage: ./loader.py [studyId] [startDay]"
        print "studyId - database id of the study"
        print "startDay - the first model day to start processing data for"
        exit(0)

    # Parse the parameters
    studyId = int(sys.argv[1])
    startDay = int(sys.argv[2])

    if not os.path.exists("out"): os.makedirs("out")
    main(studyId, startDay)

