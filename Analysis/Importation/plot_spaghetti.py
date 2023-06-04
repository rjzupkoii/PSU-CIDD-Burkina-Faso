#!/usr/bin/env python3

# plot_spaghetti.py
#
# Generate the spaghetti plots for the Burkina Faso 580Y importation manuscript.
import calendar
import datetime
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd


class DataSet:
    data = None
    
    def __init__(self, filename):
        # Load the data, filter out mutations,  and calculate the frequency
        self.data = pd.read_csv(filename)
        self.data = self.data[self.data['mutations'] == 0]
        self.data['frequency'] = self.data['weightedoccurrences'] / self.data['infectedindividuals']            

    # Get the replicates for the given combination of values.
    def get_replicates(self, month, imports, symptomatic, lower, upper):
        filtered = self.data[self.data['dayselapsed'] == np.unique(self.data['dayselapsed'])[-1]]

        # Should we return replicates with extinction?
        if lower is None and upper is not None:
            filtered = filtered[filtered['frequency'] == 0]

        # Are we just filtering on the lower bound?
        elif lower is not None and upper is None:
            filtered = filtered[filtered['frequency'] >= lower]

        # Otherwise just used the bands provided if they are provided
        elif lower is not None and upper is not None:
            filtered = filtered[(filtered['frequency'] > lower) & (filtered['frequency'] < upper)]

        # Return the results based upon the rest of the filter
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


def format_plots(plots, xlimit, ylimit, log10):
    row, col = 0, 0
    for ndx in range(1, 13):
        plots[row][col].set_xlim(xlimit)

        if log10:
            plots[row][col].set_ylim([0, 0.01])
            plots[row][col].set_yscale('symlog')
            plots[1][0].set_ylabel('Frequency ($log_{10}$)')
        else:
            plots[row][col].set_ylim([0, ylimit])
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


def generate(filename, directory, lower, upper, log10=False):
    def get_filename(symptomatic, imports):
        postfix = 's'
        if imports == 1: postfix = ''
        return 'out/{}/{}ymptomatic - {} import{}.png'.format(
            directory, ['as', 's'][symptomatic], imports, postfix)

    def get_title(symptomatic, imports):
        postfix = 's'
        if imports == 1: postfix = ''
        
        # Extinction plot of replicates with frequency = 0 
        if lower is None and  upper == 0:
            return '{}ymptomatic with {} import{} in month, extinction'.format(
                ['As', 'S'][symptomatic], imports, postfix)
        
        # Emergence plot of replicates with frequency > 0 and < 1e-3
        if lower == 0 and upper == 1e-3:
            return '{}ymptomatic with {} import{} in month, emergence (> 0 and < 0.001)'.format(
                ['As', 'S'][symptomatic], imports, postfix)

        # Establishment plot of replicates with frequency ≥ 1e-3
        if lower == 1e-3 and upper is None:
            return '{}ymptomatic with {} import{} in month, establishment (≥ 0.001)'.format(
                ['As', 'S'][symptomatic], imports, postfix)
        
        # Likely plotting everything, just note the parameters
        return '{}ymptomatic with {} import{} in month'.format(['As', 'S'][symptomatic], imports, postfix)

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
                replicates = data.get_replicates(month, imports, symptomatic, lower, upper)
                ylimit = max(ylimit, add_plot(plots[row][col], data, replicates, calendar.month_name[month]))
                
                # Update our plot index
                col += 1
                if col % 4 == 0:
                    row += 1
                    col = 0
                                
            # Format the overall plot
            format_plots(plots, xlimit, ylimit, log10)
            figure.suptitle(get_title(symptomatic, imports))
            
            # Save the plot
            plt.savefig(get_filename(symptomatic, imports), bbox_inches='tight')
            plt.close()
        
        
if __name__ == '__main__':
    FILENAME = 'data/bfa-merged.csv'
    STUDYDATE = '2007-01-01'
   
    generate(FILENAME, 'all', None, None)
    generate(FILENAME, 'extinction', None, 0)
    generate(FILENAME, 'emergence', 0, 1e-3)
    generate(FILENAME, 'establishment', 1e-3, None)