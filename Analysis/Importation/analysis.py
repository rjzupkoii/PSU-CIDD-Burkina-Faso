#!/usr/bin/env python3

##
# analysis.py
#
# Working script to evaluate the importation results.
##
import datetime
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

DATA = 'data/lowtransmission/_seasonal_immunity_{}.csv'

OFFSET = -36
STUDYDATE = '2007-01-01'

Y_LABEL = [
    '580Y Count',           '% Clin. Inf.',
    '580Y Multi Count',     '% Clin. Treated',
    '580Y Frequency',       '% Multi. Treated',
    '',                     '% Treat. Fail.',
    ]
    

def format_plot(plot, dates, label):
    # Draw the seasonality
    for year in range(2037 + OFFSET, 2038):
        plot.axvspan(datetime.datetime(year, 6, 1, 0, 0), datetime.datetime(year, 11, 1, 0, 0), alpha=0.2, color='#CCCCCC')   

    # Format the remainder of the plot
    plot.set_xlim([min(dates), max(dates)])
    plot.set_ylabel(label)
    

def update_plot(plot, dates, data):
    
    plot[0][0].plot(dates, data['580yUnweighted'])
    plot[1][0].plot(dates, data['580yMulticlonal'])
    
    y = data['580yWeighted'] / data['InfectedIndividuals']
    plot[2][0].plot(dates, y)       # 580Y Frquency
        
    y = (data['ClinicalIndividuals'] / data['InfectedIndividuals']) * 100.0
    plot[0][1].plot(dates, y)       # % Clinical Infections
    
    y = (data['Treatments'] / data['ClinicalIndividuals']) * 100.0
    plot[1][1].plot(dates, y)       # % Clinical Treated
    
    y = (data['Treatments'] / data['Multiclonal']) * 100.0
    plot[2][1].plot(dates, y)       # % Multiclonal Treated
    
    y = (data['TreatmentFailure'] / data['Treatments']) * 100.0
    plot[3][1].plot(dates, y)       # % Treatment Failures    
    

# Prepare the figure
matplotlib.rc_file('matplotlibrc-line')
figure, plot = plt.subplots(4, 2)

for ndx in range(1, 51):
    # Load the data
    data = pd.read_csv(DATA.format(ndx), sep=',', header=0)

    # Filter to a single climatic zone for now
    data = data[data['ClimaticZone'] == 1]

    # Filter to the last three years
    date = data['DaysElapsed'].tolist()[OFFSET]
    data = data[data['DaysElapsed'] > date]

    # Prepare the dates from the first data file
    if ndx == 1: 
        startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
        dates = [startDate + datetime.timedelta(days=value) for value in data['DaysElapsed']]    
        print(data.columns)

    # Plot the data
    update_plot(plot, dates, data)
    
# Format the figure    
plot[3, 0].axis('off')
for ndy in range(0, len(plot)):
    for ndx in range(0, len(plot[ndy])):        
        print(ndy, ndx, ndy * 2 + ndx, Y_LABEL[ ndy * 2 + ndx])
        if ndy == 3 and ndx == 0: continue
        format_plot(plot[ndy][ndx], dates, Y_LABEL[ndy * 2 + ndx])






