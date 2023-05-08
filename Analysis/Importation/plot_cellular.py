#!/usr/bin/env python3

##
# plot_cellular.py
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
    'bfa-steady-80-20.yml'   : [0, 1],
    'bfa-seasonal-50-50.yml' : [1, 0],
    'bfa-seasonal-80-20.yml' : [1, 1]
    }

STUDYDATE = '2007-01-01'
  

def figure(column, ylabel, filename, ylimit = None):
    # Sub function to render the actual data on the plot
    def plot_data(data, dates, ax):
        # Find the bounds of the data
        upper = np.percentile(data, 75, axis=0)
        median = np.percentile(data, 50, axis=0)
        lower = np.percentile(data, 25, axis=0)            
        
        # Add the data to the subplot
        ax.plot(dates, median, zorder=100)
        color = scale_luminosity(ax.lines[-1].get_color(), 1)
        ax.fill_between(dates, lower, upper, alpha=0.5, facecolor=color, zorder=100)    
    

    # Load the data
    data = pd.read_csv('data/bfa-cellular.csv')
    
    # Prepare the dates in the correct format
    dates = pd.unique(data.dayselapsed)
    startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
    dates = [startDate + datetime.timedelta(days = int(x)) for x in dates]  
    
    # Setup the figure
    matplotlib.rc_file('include/matplotlibrc-line')
    figure, plots = plt.subplots(2, 2)
    
    for key in LAYOUT:
        # Filter the data for this plot
        filtered = data[data.filename == key]
        replicates = pd.unique(filtered.id)
        if len(replicates) == 0: continue
        
        dataset = []    
        for ndx in range(len(replicates)):
            values = filtered[filtered.id == replicates[ndx]][column]
            if len(dataset) != 0: 
                dataset = np.vstack((dataset, values))
            else:
                dataset = values
              
        # Add the data to the plot
        plot = plots[LAYOUT[key][0], LAYOUT[key][1]]
    
        # Draw the actual plot data
        plot_data(dataset, dates, plot)

        # Draw the seasonality        
        if LAYOUT[key][0] == 1:            
            for year in range(2018, 2038):
                plot.axvspan(datetime.datetime(year, 6, 1, 0, 0), datetime.datetime(year, 10, 1, 0, 0), alpha=0.2, color='#CCCCCC')            
    
        # Format the plot
        plot.set_xlim([min(dates), max(dates)])
        if ylimit is not None:
            plot.set_ylim(ylimit)
        if LAYOUT[key][1] == 0:
            plot.set_ylabel(ylabel)
        result = re.search(r"bfa-s([a-z]*)-(.*).yml", key)
        plot.title.set_text('S{} {}'.format(result.group(1), result.group(2)))
        
    # Save the plot
    plt.savefig(filename, bbox_inches='tight')
    plt.close()
    
    
if __name__  == '__main__':
    figure('clinicalepisodes', 'Total Clinical Episodes', 'out/clinical.png', [3900, 18000])
    figure('percent_treated', 'Mean Treatment Seeking (%)', 'out/treated.png')
    figure('frequency', '580Y Frequency', 'out/frequency.png', [0, 0.4])
    figure('weighted_580y', '580Y Weighted Count', 'out/weighted.png', [0, 60000])
    
    
    