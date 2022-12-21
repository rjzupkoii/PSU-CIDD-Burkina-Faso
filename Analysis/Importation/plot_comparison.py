#!/usr/bin/env python3

##
# analysis.py
#
# Working script to evaluate the importation results.
##
import datetime
import matplotlib
import matplotlib.pyplot as plt
import pandas as pd

DATA_LOW = 'data/lowtransmission/_seasonal_immunity_{}.csv'
DATA_HIGH = 'data/hightransmission/_seasonal_immunity_{}.csv'

OFFSET = -144
STUDYDATE = '2007-01-01'

TITLE = ['Low, 3 mo.', 'High, 3 mo.',
         'Low, 4 mo.', 'High, 4 mo.', 
         'Low, 5 mo.', 'High, 5 mo.',
         ]


def format_plot(plot, dates, title, ylabel):
    # Draw the seasonality
    for year in range(2037 + OFFSET, 2038):
        plot.axvspan(datetime.datetime(year, 6, 1, 0, 0), datetime.datetime(year, 11, 1, 0, 0), alpha=0.2, color='#CCCCCC')   

    # Format the remainder of the plot
    plot.set_xlim([min(dates), max(dates)])
    plot.set_ylabel(ylabel)
    plot.set_title(title)
    

def generate_plot(filename, column):
    for ndx in range(1, 51):
        # Load the data
        data = pd.read_csv(filename.format(ndx), sep=',', header=0)
    
        # Print the column names on the first pass
        if ndx == 1 and column == 0: print(data.columns)
    
        # Prepare the list of dates
        dates = data[data['ClimaticZone'] == 0]
        dates = dates['DaysElapsed'].tolist()
        dates = dates[OFFSET:]
    
        # Filter the data to the right date range and parse them
        data = data[data['DaysElapsed'] >= dates[0]]
        
        # Format the date labels
        startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
        dates = [startDate + datetime.timedelta(days=value) for value in dates]   
    
        # Plot the data
        for ndx in range(0, 3):
            filtered = data[data['ClimaticZone'] == ndx]        
            
            y = filtered['580yWeighted'] / filtered['InfectedIndividuals']
            
            plot[ndx][column].plot(dates, y)    
            
    return dates
    

# Prepare the figure
matplotlib.rc_file('matplotlibrc-line')
figure, plot = plt.subplots(3, 2)

# Add the data
generate_plot(DATA_LOW, 0)
dates = generate_plot(DATA_HIGH, 1)
    
# Format the figure    
for ndy in range(0, len(plot)):
    for ndx in range(0, len(plot[ndy])):        
        format_plot(plot[ndy][ndx], dates, TITLE[ndy * 2 + ndx], '580Y Frequency')






