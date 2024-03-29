#!/usr/bin/env python3

##
# plot_treatments.py
#
# Script to plot the comparison of the total treatments between cellular studies.
##
import datetime
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import re
import sys

# From the PSU-CIDD-MaSim-Support repository
sys.path.insert(1, '../../../PSU-CIDD-MaSim-Support/Python/include')
from plotting import scale_luminosity


LAYOUT = {
    'bfa-steady-50-50.yml'   : [0, 0],
    'bfa-steady-80-40.yml'   : [0, 1],
    'bfa-seasonal-50-50.yml' : [1, 0],
    'bfa-seasonal-80-40.yml' : [1, 1]
    }

LIMIT = [[49, 51], [50, 75]]
STUDYDATE = '2007-01-01'

def plot_data(data, dates, ax):
    # Find the bounds of the data
    upper = np.percentile(dataset, 75, axis=0)
    median = np.percentile(dataset, 50, axis=0)
    lower = np.percentile(dataset, 25, axis=0)            
    
    # Add the data to the subplot
    ax.plot(dates, median, zorder=100)
    color = scale_luminosity(ax.lines[-1].get_color(), 1)
    ax.fill_between(dates, lower, upper, alpha=0.5, facecolor=color, zorder=100)    
    

matplotlib.rc_file('include/matplotlibrc-line')
data = pd.read_csv('data/bfa-cellular.csv')
studies = pd.unique(data.filename)

dates = pd.unique(data.dayselapsed)

# Prepare the date format
startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
dates = [startDate + datetime.timedelta(days = int(x)) for x in dates]  


figure, plots = plt.subplots(2, 2)
figure.suptitle('Under-5 vs. Over-5 Total Treamtment Seeking')

row, col = 0, 0
for key in LAYOUT:
    
    dataset = []
    
    # Filter the data for this plot
    filtered = data[data.filename == key]
    replicates = pd.unique(filtered.id)
    
    if len(replicates) == 0: continue
        
    for ndx in range(len(replicates)):
        values = filtered[filtered.id == replicates[ndx]].percent_treated
        if len(dataset) != 0: 
            dataset = np.vstack((dataset, values))
        else:
            dataset = values
          
    # Add the data to the plot
    plot = plots[LAYOUT[key][0], LAYOUT[key][1]]

    # Draw the actual plot data
    plot_data(dataset, dates, plot)

    # Format the plot
    plot.set_xlim([min(dates), max(dates)])    
    if LAYOUT[key][1] == 0:
        plot.set_ylim([49, 51])
        plot.set_ylabel('Mean Treatment Seeking')
    else:
        plot.set_ylim([76.5, 80])
        
    if LAYOUT[key][0] == 1:
        # Draw the seasonality
        for year in range(2018, 2024):
            plot.axvspan(datetime.datetime(year, 6, 1, 0, 0), datetime.datetime(year, 10, 1, 0, 0), alpha=0.2, color='#CCCCCC')            
        
    # Format the title
    result = re.search(r"bfa-s([a-z]*)-(.*).yml", key)
    plot.title.set_text('S{} {}'.format(result.group(1), result.group(2)))
    
        
        
    
    
    