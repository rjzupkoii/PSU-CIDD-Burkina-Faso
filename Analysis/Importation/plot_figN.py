#!/usr/bin/env python3

# plot_figN.py
#
# Generate the Figure NN plot for the Burkina Faso 580Y importation manuscript.
import calendar
import datetime
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import os


class DataSet:
    data = None
    
    def __init__(self, filename):
        # Load the data, filter out mutations,  and calculate the frequency
        self.data = pd.read_csv(filename)
        self.data = self.data[self.data['mutations'] == 0]
        self.data['frequency'] = self.data['weightedoccurrences'] / self.data['infectedindividuals']            

    # Get the replicates for the given combination of values.
    def get_replicates(self, month, imports, symptomatic, threshold):
        filtered = self.data[self.data['dayselapsed'] == np.unique(self.data['dayselapsed'])[-1]]
        if threshold == 0:
            filtered = filtered[filtered['frequency'] == 0]
        else:
            filtered = filtered[filtered['frequency'] >= threshold]
        return np.unique(filtered[(filtered['month'] == month) &  
                                  (filtered['imports'] == imports) & 
                                  (filtered['symptomatic'] == symptomatic)]['replicateid'])
    
    # Get a deep copy of the data
    def get_data(self):
        return self.data.copy()
    
    def get_dates(self):
        startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
        dates = np.unique(self.data['dayselapsed'])
        dates = [startDate + datetime.timedelta(days = int(x)) for x in dates]
        return dates.copy()


def add_plot(plot, dataset, replicates, month):
    # Start by setting the title of the plot
    plot.title.set_text('{}, n = {}'.format(month, len(replicates)))
    
    # Return if there is nothing else to do
    ylimit = 0
    if len(replicates) == 0: 
        return ylimit
    
    # Add the replicates to the plot
    data = dataset.get_data()
    dates = dataset.get_dates()
    for replicate in replicates:
        plot.plot(dates, data[data['replicateid'] == replicate]['frequency'])
        ylimit = max(ylimit, max(data[data['replicateid'] == replicate]['frequency']))
                
    # Return the highest y-limit
    return ylimit


def format_plots(plots, xlimit, ylimit):
    row, col = 0, 0
    for ndx in range(1, 13):
        plots[row][col].set_xlim(xlimit)
        plots[row][col].set_ylim([0, ylimit])
                
        # Add the y-axis label
        plots[1][0].set_ylabel('Frequency')
        
        # Hide the labels if they aren't needed
        if col > 0: 
            plots[row][col].axes.get_yaxis().set_ticklabels([])
        if row < 2:
            plots[row][col].axes.get_xaxis().set_ticklabels([])
        
        # Update our plot index
        col += 1
        if col % 4 == 0:
            row += 1
            col = 0    


def generate(filename, threshold, directory):
    def get_filename(symptomatic, imports):
        postfix = 's'
        if imports == 1: postfix = ''
        return 'out/{}/{}ymptomatic - {} import{}.png'.format(
            directory, ['as', 's'][symptomatic], imports, postfix)

    def get_title(symptomatic, imports):
        postfix = 's'
        if imports == 1: postfix = ''
        symbol = '≥'
        if threshold == 0: symbol = '='
        return '{}ymptomatic with {} import{} in month, filter{}{}'.format(
            ['As', 'S'][symptomatic], imports, postfix, symbol, threshold)


    # Make sure the directory exists
    os.makedirs('out/{}'.format(directory), exist_ok=True)

    # Set the overall figure format
    matplotlib.rc_file('include/matplotlibrc-line')
    
    data = DataSet(filename)
    xlimit = [min(data.get_dates()), max(data.get_dates())]
    
    for symptomatic in [0, 1]:
        for imports in [1, 3, 6, 9]:
    
            # Set-up a new plot to work with
            figure, plots = plt.subplots(3, 4)
            figure.autofmt_xdate(rotation=45)
            
            # Add the data
            row, col, ylimit = 0, 0, 0
            for month in range(1, 13):
            
                # Find the replicates that need to be plotted
                replicates = data.get_replicates(month, imports, symptomatic, threshold)
                ylimit = max(ylimit, add_plot(plots[row][col], data, replicates, calendar.month_name[month]))
                
                # Update our plot index
                col += 1
                if col % 4 == 0:
                    row += 1
                    col = 0    
                                
            # Format the overall plot
            format_plots(plots, xlimit, ylimit)
            figure.suptitle(get_title(symptomatic, imports))
            
            # Save the plot
            plt.savefig(get_filename(symptomatic, imports), bbox_inches='tight')
            plt.close()
        
        
if __name__ == '__main__':
    FILENAME = 'data/bfa-merged.csv'
    STUDYDATE = '2007-01-01'
   
    generate(FILENAME, 0, 'zero')
    generate(FILENAME, 1e-4, 'positive')