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

# Connection string for the database
CONNECTION = "host=masimdb.vmhost.psu.edu dbname=burkinafaso user=sim password=sim"

# Default path template for downloaded replicates
PATH_TEMPLATE = "out/{}"

# Default filename path template for downloaded replicates
FILE_TEMPLATE = "out/{}/{}-summary.csv"

# Indices in getReplicates query
LABEL = 0
REPLICATEID = 4
COMPLETE = 5


# Return the components of the frequency data for each cell after the burn-in period is complete
def get_frequency_subset(replicateId, subset):
    sql = """   
        SELECT dayselapsed, l.x, l.y, infectedindividuals,
            sum(clinicaloccurrences) AS clinicaloccurrences,
            sum(weightedoccurrences) AS weightedoccurrences
        FROM (
            SELECT md.replicateid, md.id, mgd.locationid, md.dayselapsed,
                sum(CASE WHEN g.name ~ '^.....Y..' THEN mgd.clinicaloccurrences ELSE 0 END) AS clinicaloccurrences,
                sum(CASE WHEN g.name ~ '^.....Y..' THEN mgd.weightedoccurrences ELSE 0 END) AS weightedoccurrences
            FROM sim.monthlydata md
                INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id
                INNER JOIN sim.genotype g ON g.id = mgd.genomeid
            WHERE md.replicateid = %(replicateId)s AND md.dayselapsed in ({})
            GROUP BY md.id, mgd.locationid) one
        INNER JOIN (
            SELECT md.id, msd.locationid, msd.infectedindividuals 
            FROM sim.monthlydata md
                INNER JOIN sim.monthlysitedata msd ON msd.monthlydataid = md.id
            WHERE md.replicateid = %(replicateId)s AND md.dayselapsed in ({})) two ON one.id = two.id AND one.locationid = two.locationid
        INNER JOIN sim.location l on l.id = one.locationid
        GROUP BY dayselapsed, l.x, l.y, infectedindividuals""".format(subset, subset)
    return select(sql, {'replicateId':replicateId, 'startDay':startDay})


# Get a list of all of the studies (i.e., configurations) associated with this studyId
def get_studies(studyId):
    sql = """
    SELECT c.id, replace(c.filename, '.yml', '') AS filename
    FROM sim.configuration c
    WHERE c.studyid = %(studyId)s"""
    return select(sql, {'studyId':studyId})


# Return all of the replicates for the given configuration id
def get_replicates(configurationId, label):
    sql = """
    SELECT %(label)s as label,
        nrows, ncols, c.id AS configurationid, r.id AS replicateid,
	    CASE WHEN r.endtime IS NULL THEN 0 ELSE 1 END As complete
    FROM sim.configuration c INNER JOIN sim.replicate r ON r.configurationid = c.id
    WHERE c.id = %(configurationId)s"""
    return select(sql, {'configurationId':configurationId, 'label':label})


# Get the summary data for the given replicate after the burn-in period is complete
def get_summary(replicateId, startDay):
    sql = """
        SELECT dayselapsed, l.district,
            sum(infectedindividuals) AS infectedindividuals,
            sum(occurrences) AS occurrences,
            sum(clinicaloccurrences) AS clinicaloccurrences,
            sum(weightedoccurrences) AS weightedoccurrences
        FROM (
            SELECT md.replicateid, md.id, mgd.locationid, md.dayselapsed,
                sum(CASE WHEN g.name ~ '^.....Y..' THEN mgd.occurrences ELSE 0 END) AS occurrences,
                sum(CASE WHEN g.name ~ '^.....Y..' THEN mgd.clinicaloccurrences ELSE 0 END) AS clinicaloccurrences,
                sum(CASE WHEN g.name ~ '^.....Y..' THEN mgd.weightedoccurrences ELSE 0 END) AS weightedoccurrences
            FROM sim.monthlydata md
                INNER JOIN sim.monthlygenomedata mgd ON mgd.monthlydataid = md.id
                INNER JOIN sim.genotype g ON g.id = mgd.genomeid
            WHERE md.replicateid = %(replicateId)s AND md.dayselapsed > %(startDay)s
            GROUP BY md.id, mgd.locationid) one
        INNER JOIN (
            SELECT md.id, msd.locationid, msd.infectedindividuals 
            FROM sim.monthlydata md
                INNER JOIN sim.monthlysitedata msd ON msd.monthlydataid = md.id
            WHERE md.replicateid = %(replicateId)s AND md.dayselapsed > %(startDay)s) two ON one.id = two.id AND one.locationid = two.locationid
        INNER JOIN sim.location l on l.id = one.locationid
        GROUP BY dayselapsed, l.district"""
    return select(sql, {'replicateId':replicateId, 'startDay':startDay})


# Process the frequency data by aggregating it together across all cells and replicates for each rate
def process_frequencies(replicates, subset):
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
                save_frequencies(data, currentRate)
                del data
            replicateCount = 0
            currentRate = replicate[0]
            data = {}

        # Run a short query to see if we have anything to work with
        for row in get_frequency_subset(replicate[REPLICATEID], subset):
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
    save_frequencies(data, currentRate)
    progressBar(total + 1, len(replicates) + 1) 


# Process the summary data by appending it for each complete replicate and day
def process_summaries(replicates, burnIn):
    # Update the user
    print("Processing {} replicate summaries...".format(len(replicates)))

    # Note the progress
    total = 0
    progressBar(total, len(replicates) + 1)

    # Iterate through all of the rows
    for replicate in replicates:

        # Only download complete summaries
        if replicate[COMPLETE] == False: continue

        # Check to see if the work has already been done
        filename = FILE_TEMPLATE.format(replicate[LABEL], replicate[REPLICATEID])
        if not os.path.exists(filename):
            save_summary(replicate[LABEL], replicate[REPLICATEID], burnIn)
        
        # Note the progress
        total = total + 1
        progressBar(total, len(replicates) + 1)

    # Note that we are done
    progressBar(len(replicates) + 1, len(replicates) + 1) 


def save_frequencies(data, rate):
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


# Query for the summary information and save it to disk
def save_summary(rate, replicateId, burnIn):
    # Create the path if it doesn't exist
    path = PATH_TEMPLATE.format(rate)
    if not os.path.exists(path): os.makedirs(path)

    # Load the data
    data = get_summary(replicateId, burnIn)   

    # Save the data to disk as a CSV file, replicateid is redundant, but useful
    # when scripting to avoid messing around with the filename in Matlab
    filename = FILE_TEMPLATE.format(rate, replicateId) 
    with open(filename, "wb") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["replicateId", "days", "district", "infectedindividuals", "occurrences", "clinicaloccurrrences", "weightedoccurrences"])
        for row in data:
            data = [replicateId] + list(row)
            writer.writerow(data)


def main(studyId, burnIn, subset):

    # Get the studies
    print("Querying for studies...")
    studies = get_studies(studyId)
    if len(studies) == 0:
        print("No studies to process!")
        return
    
    # Let the user know what is going on
    if len(studies) == 1:
        print("Processing study...")
    else:
        print("Processing {} studies...".format(len(studies)))
    
    counter = 1
    for study in studies:
        # Process the replicates for this study
        replicates = get_replicates(study[0], study[1])
        process_frequencies(replicates, subset)
        process_summaries(replicates, burnIn)
        
        # Update the status for the user
        if len(studies) > 1:
            print("{} of {} studies complete".format(counter, len(studies)))
            counter += 1


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
        print "studyId  - database id of the study"
        print "startDay - the first model day to start processing data for"
        exit(0)

    # Prepare the environment
    if not os.path.exists("out"): 
        os.makedirs("out")
    else:
        for filename in glob.glob("out/*summary*.csv"): os.remove(filename)

    # Parse the parameters
    studyId = int(sys.argv[1])
    startDay = int(sys.argv[2])

    # TODO Find a better way of getting the subset
    # October every three years starting in 2020 - 5022, 6117, 7213, 8309, 9405, 10866
    main(studyId, startDay, "5022, 6117, 7213, 8309, 9405, 10866")

