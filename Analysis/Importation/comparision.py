#!/usr/bin/env python3

##
# comparision.py
#
# Script to plot the comparision between cellular studies.
##
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import sys

# From the PSU-CIDD-MaSim-Support repository
sys.path.insert(1, '../../../../PSU-CIDD-MaSim-Support/Python/include')
from plotting import scale_luminosity


LAYOUT = {
    'bfa-steady-50-50.yml'   : [0, 0],
    'bfa-steady-80-40.yml'   : [0, 1],
    'bfa-seasonal-50-50.yml' : [1, 0],
    'bfa-seasonal-80-40.yml' : [1, 1]
    }

LIMIT = [[49, 51], [50, 75]]

def plot_data(data, dates, ax):
    # Find the bounds of the data
    upper = np.percentile(dataset, 75, axis=0)
    median = np.percentile(dataset, 50, axis=0)
    lower = np.percentile(dataset, 25, axis=0)            
    
    # Add the data to the subplot
    ax.plot(dates, median)
    color = scale_luminosity(ax.lines[-1].get_color(), 1)
    ax.fill_between(dates, lower, upper, alpha=0.5, facecolor=color)    
    

data = pd.read_csv('../data/bfa-cellular.csv')
studies = pd.unique(data.filename)
dates = pd.unique(data.dayselapsed)

figure, plots = plt.subplots(2, 2)
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
    plot_data(dataset, dates, plot)            
    
    # Format the plot
    if LAYOUT[key][1] == 0:
        plot.set_ylim([49, 51])
    else:
        plot.set_ylim([76.5, 80])
    
    
    