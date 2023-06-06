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
    ## Left Column
    '580Y Count',
    '580Y Multi Count',     
    '580Y Frequency',
    'MOI',                  
    None,       
    
    ## Right column
    'Mean Theta',
    'New Inf.',
    '% Clin. Inf.',
    '% Clin. Treated',
    '% Treat. Fail.',    
    ]
    
ROWS = 5
COLUMNS = 2

def format_plot(plot, dates, label):
    # Draw the seasonality
    for year in range(2037 + OFFSET, 2038):
        plot.axvspan(datetime.datetime(year, 6, 1, 0, 0), datetime.datetime(year, 11, 1, 0, 0), alpha=0.2, color='#CCCCCC')   

    # Format the remainder of the plot
    plot.set_xlim([min(dates), max(dates)])
    plot.set_ylabel(label)
    

def update_plot(plot, dates, data):
    
    ## Left column
    plot[0][0].plot(dates, data['580yUnweighted'])
    plot[1][0].plot(dates, data['580yMulticlonal'])
    
    y = data['580yWeighted'] / data['InfectedIndividuals']
    plot[2][0].plot(dates, y)       # 580Y Frquency
        
    # MOI = (Clones - (Clones - Infections)) / Multiclonal
    y = (data['ParasiteClones'] - (data['ParasiteClones'] - data['InfectedIndividuals'])) / data['Multiclonal']
    plot[3][0].plot(dates, y)       # MOI
    
    
    ## Right column
    plot[0][1].plot(dates, data['MeanTheta'])
    plot[1][1].plot(dates, data['NewInfections'])
        
    y = (data['ClinicalIndividuals'] / data['InfectedIndividuals']) * 100.0
    plot[2][1].plot(dates, y)       # % Clinical Infections
    
    y = (data['Treatments'] / data['ClinicalIndividuals']) * 100.0
    plot[3][1].plot(dates, y)       # % Clinical Treated
        
    y = (data['TreatmentFailure'] / data['Treatments']) * 100.0
    plot[4][1].plot(dates, y)       # % Treatment Failures    
    

# Prepare the figure
matplotlib.rc_file('matplotlibrc-line')
figure, plot = plt.subplots(ROWS, COLUMNS)

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
plot[4, 0].axis('off')
for ndy in range(0, COLUMNS):
    for ndx in range(0, ROWS):
        label = Y_LABEL[ndy * ROWS + ndx]
        print(ndy, ndx, ndy * ROWS + ndx, label)
        if label is None: continue
        format_plot(plot[ndx][ndy], dates, label)    
