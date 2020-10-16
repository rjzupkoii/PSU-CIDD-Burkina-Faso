#!/usr/bin/python

import datetime 
import psycopg2

# Connection string for the database
CONNECTION = "host=masimdb.vmhost.psu.edu dbname=burkinafaso user=sim password=sim"

REPLICATES = """
select r.id
from sim.configuration c
  inner join sim.replicate r on r.configurationid = c.id
where c.studyid = 2"""


def getReplicates():
    # Open the connection
    connection = psycopg2.connect(CONNECTION)
    cursor = connection.cursor()

    # Execute the query, note the rows
    cursor.execute(REPLICATES)
    rows = cursor.fetchall()

    # Clean-up and return
    cursor.close()
    connection.close()

    return rows


def deleteReplicate(replicateId):

    # Open the connection
    connection = psycopg2.connect(CONNECTION)
    connection.autocommit = True
    cursor = connection.cursor()

    # Run the stored procedure
    print "{} - Deleting {}".format(datetime.datetime.now(), replicateId)
    SQL = 'CALL delete_replicate(%(replicateId)s, True)'
    cursor.execute(SQL, {'replicateId': replicateId})
    
    # Clean-up and return
    cursor.close()
    connection.close()


replicates = getReplicates()
for row in replicates:
    deleteReplicate(row[0])