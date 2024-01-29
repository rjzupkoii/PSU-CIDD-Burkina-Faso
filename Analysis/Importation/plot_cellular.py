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
import os
import pandas as pd
import sys

# From the PSU-CIDD-MaSim-Support repository
sys.path.insert(1, '../../../PSU-CIDD-MaSim-Support/Python/include')
from plotting import scale_luminosity


STUDYDATE = '2007-01-01'
  

def figure(data_file, layout, column, ylabel, filename, xlimit = None, ylimit = None):
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
    data = pd.read_csv(data_file)
    
    # Prepare the dates in the correct format
    dates = pd.unique(data.dayselapsed)
    startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
    dates = [startDate + datetime.timedelta(days = int(x)) for x in dates]
    
    # Setup the figure
    matplotlib.rc_file('include/matplotlibrc-line')
    figure, plots = plt.subplots(2, 2)
    
    for key in layout:
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
        plot = plots[layout[key][0], layout[key][1]]
    
        # Draw the actual plot data
        plot_data(dataset, dates, plot)

        # Draw the seasonality        
        if layout[key][0] == 1:            
            for year in range(2018, 2068):
                plot.axvspan(datetime.datetime(year, 6, 1, 0, 0), datetime.datetime(year, 10, 1, 0, 0), alpha=0.2, color='#CCCCCC')            
    
        # Format the plot
        if xlimit is not None:
            plot.set_xlim(xlimit)    
        else:
            plot.set_xlim([min(dates), max(dates)])
        if ylimit is not None:
            plot.set_ylim(ylimit)
        if layout[key][1] == 0:
            plot.set_ylabel(ylabel)
        
        plot.title.set_text(get_title(key))
        
    # Set the primary title
    figure.suptitle(get_title(data_file))
        
    # Save the plot
    plt.savefig(filename, bbox_inches='tight', dpi=150)
    plt.close()
    

def get_title(filename):
    MAPPING = {
        # 2x Grid based studies
        'bfa-2x-grid-ns-balanced.yml'   : 'No Season, 50-50',
        'bfa-2x-grid-ns-unbalanced.yml' : 'No Season, 87-23.4',
        'bfa-2x-grid-balanced.yml'      : 'Seasonal, 50-50',
        'bfa-2x-grid-unbalanced.yml'    : 'Seasonal, 87-23.4',

        # 3x Grid based studies
        'bfa-grid-ns-balanced.yml'   : 'No Season, 50-50',
        'bfa-grid-ns-unbalanced.yml' : 'No Season, 87-23.4',
        'bfa-grid-balanced.yml'      : 'Seasonal, 50-50',
        'bfa-grid-unbalanced.yml'    : 'Seasonal, 87-23.4',
        
        # Single cell studies
        'bfa-steady-balanced.yml'   : 'No Season, 50-50',
        'bfa-steady-unbalanced.yml'   : 'No Season, 87-23.4',
        'bfa-seasonal-balanced.yml' : 'Seasonal, 50-50',
        'bfa-seasonal-unbalanced.yml' : 'Seasonal, 87-23.4',
        
        # Primary titles
        'data/bfa-cellular.csv' : 'Single Cell Study',
        'data/bfa-2x-grid.csv'  : '2x2 Grid Study',
        'data/bfa-3x-grid.csv'  : '3x3 Grid Study'
    }
    return MAPPING[filename]


def plot_cell():
    FILENAME = 'data/bfa-cellular.csv'
    LAYOUT = {
        'bfa-steady-balanced.yml'   : [0, 0],
        'bfa-steady-unbalanced.yml'   : [0, 1],
        'bfa-seasonal-balanced.yml' : [1, 0],
        'bfa-seasonal-unbalanced.yml' : [1, 1]
    }

    figure(FILENAME, LAYOUT, 'clinicalepisodes', 'Total Clinical Episodes', 'out/clinical.png', ylimit=[4500, 36000])
    figure(FILENAME, LAYOUT, 'percent_treated', 'Mean Treatment Seeking (%)', 'out/treated.png')
    figure(FILENAME, LAYOUT, 'frequency', '580Y Frequency', 'out/frequency.png', ylimit=[0, 1])
    figure(FILENAME, LAYOUT, 'weighted_580y', '580Y Weighted Count', 'out/weighted.png', ylimit=[0, 375000])


def plot_2x_grid():
    FILENAME = 'data/bfa-2x-grid.csv'
    LAYOUT = {
        'bfa-2x-grid-ns-balanced.yml'   : [0, 0],
        'bfa-2x-grid-ns-unbalanced.yml' : [0, 1],
        'bfa-2x-grid-balanced.yml'      : [1, 0],
        'bfa-2x-grid-unbalanced.yml'    : [1, 1]
    }

    figure(FILENAME, LAYOUT, 'clinicalepisodes', 'Total Clinical Episodes', 'out/2x_clinical.png', ylimit=[8000, 80000])
    figure(FILENAME, LAYOUT, 'percent_treated', 'Mean Treatment Seeking (%)', 'out/2x_treated.png')
    figure(FILENAME, LAYOUT, 'frequency', '580Y Frequency', 'out/2x_frequency.png', ylimit=[0, 1])
    figure(FILENAME, LAYOUT, 'weighted_580y', '580Y Weighted Count', 'out/2x_weighted.png', ylimit=[0, 600000])  


def plot_3x_grid():
    FILENAME = 'data/bfa-3x-grid.csv'
    LAYOUT = {
        'bfa-grid-ns-balanced.yml'   : [0, 0],
        'bfa-grid-ns-unbalanced.yml' : [0, 1],
        'bfa-grid-balanced.yml'      : [1, 0],
        'bfa-grid-unbalanced.yml'    : [1, 1]
    }

    # The figures across the full time frame
    figure(FILENAME, LAYOUT, 'clinicalepisodes', 'Total Clinical Episodes', 'out/3x_clinical.png', ylimit=[5000, 91000])
    figure(FILENAME, LAYOUT, 'percent_treated', 'Mean Treatment Seeking (%)', 'out/3x_treated.png')
    figure(FILENAME, LAYOUT, 'frequency', '580Y Frequency', 'out/3x_frequency.png', ylimit=[0, 1])
    figure(FILENAME, LAYOUT, 'weighted_580y', '580Y Weighted Count', 'out/3x_weighted.png', ylimit=[0, 640000])
    
    # The figures across a ten year time frame
    xlimit = [datetime.datetime(2040, 1, 1), datetime.datetime(2045, 12, 31)]
    figure(FILENAME, LAYOUT, 'clinicalepisodes', 'Total Clinical Episodes', 'out/5year_clinical.png', 
            xlimit=xlimit, ylimit=[10000, 55000])
    figure(FILENAME, LAYOUT, 'percent_treated', 'Mean Treatment Seeking (%)', 'out/5year_treated.png', xlimit=xlimit)
    figure(FILENAME, LAYOUT, 'frequency', '580Y Frequency', 'out/5year_frequency.png',
            xlimit=xlimit, ylimit=[0, 0.7])
    figure(FILENAME, LAYOUT, 'weighted_580y', '580Y Weighted Count', 'out/5year_weighted.png', 
           xlimit=xlimit, ylimit=[0, 250000])
    

if __name__  == '__main__':
    # Make sure the out directory exists
    os.makedirs('out', exist_ok=True)    

    # Generate the plots
    plot_cell()
    plot_2x_grid()
    plot_3x_grid()
    
    