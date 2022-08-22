#!/usr/bin/env python3

##
# plot_fig3.py
#
# Generate the Figure Three plot for the Burkina Faso 580Y importation manuscript.
##
import datetime
import math
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd
import sys

# From the PSU-CIDD-MaSim-Support repository
sys.path.insert(1, '../../../PSU-CIDD-MaSim-Support/Python/include')
from plotting import format_ticks, scale_luminosity

def main():
    dates, data = prepare('data/denovo')
    plot(dates, data)


def prepare(path, start = -61, end = -24):
    VARIABLES =  ['Phi', 'MeanTheta', 'NewInfections', 'Treatments']    
    
    # Build the dictionary that will be used to store the data
    dates, data = [], {}
    for key in VARIABLES:
        data[key] = []

    # Scan the directory for each file
    ndx = 0
    for file in os.scandir(path):
        replicate = pd.read_csv(file)
        replicate = replicate[replicate['DaysElapsed'] > (365 * 11)]
        for key in VARIABLES:
            data[key].append([])

        if len(dates) == 0:
            dates = replicate['DaysElapsed'].unique().tolist()
            dates = dates[start:end]
        for date in dates:
            byDate = replicate[replicate['DaysElapsed'] == date]
            for key in VARIABLES:
                if key == 'Phi':
                    data[key][ndx].append(sum(byDate['ClinicalIndividuals']) / sum(byDate['InfectedIndividuals']))
                elif key == 'MeanTheta':
                    data[key][ndx].append(np.mean(byDate['MeanTheta']))
                else:
                    data[key][ndx].append(math.log10(sum(byDate[key])))
    
        # Update the replicate count
        ndx += 1

    # Return the results
    print('Replicates: {}'.format(ndx))
    return dates, data


def plot(dates, data):
    STUDYDATE = '2007-01-01'
    color = iter(['#332288', '#88CCEE', '#CC6677', '#117733'])
    label = iter([r'$\varphi$', r'$\theta_{pop}$', 'New Infections', 'Treatments'])
    
    # Prepare the date format
    startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
    dates = [startDate + datetime.timedelta(days=x) for x in dates]    
    
    # Prepare the plot
    matplotlib.rc_file('matplotlibrc-line')
    fig, left = plt.subplots()
    right = left.twinx()
    
    # Draw the seasonality
    for year in [2033, 2034, 2035]:
        left.axvspan(datetime.datetime(year, 6, 1, 0, 0), datetime.datetime(year, 11, 1, 0, 0), alpha=0.2, color='#CCCCCC')
    
    # Add the study data
    for key in ['Phi', 'MeanTheta']:
        add_plot(left, dates, data[key], next(color), next(label))
    for key in ['NewInfections', 'Treatments']:
        add_plot(right, dates, data[key], next(color), next(label), style='--')
    
    # Set the left y-axis label and tick values
    left.set_ylabel(r'$\varphi$ / $\theta_{pop}$ (Solid)')
    left.set_ylim([0, 0.5])
    ticks = left.get_yticks()
    left.set_yticks(ticks)
    ticks = ['{:.1f}'.format(value) for value in ticks]
    ticks[0] = ''
    left.set_yticklabels(ticks)
    
    # Set the right y-axis label and tick values
    right.set_ylabel('Treatments / New Infections (Dashed)')
    right.set_ylim([5, 7])
    ticks = right.get_yticks()
    right.set_yticks(ticks)
    ticks = format_ticks([math.pow(10, value) for value in ticks])[1]
    ticks[0] = ''    
    right.set_yticklabels(ticks)
    
    # Set the x label, legend
    left.set_xlabel('Month')
    left_lines, left_labels = left.get_legend_handles_labels()
    right_lines, right_labels = right.get_legend_handles_labels()
    left.legend(left_lines + right_lines, left_labels + right_labels, loc='center right', frameon=False)
    
    # Save the plot
    fig.savefig('plots/manuscript/MS BFA, Fig. 3.png', bbox_inches='tight', dpi=150)
    fig.savefig('plots/manuscript/MS BFA, Fig. 3.svg', format='svg')
    

def add_plot(axis, dates, values, color, label, style='-'):
    upper = np.percentile(values, 97.5, axis=0)
    median = np.percentile(values, 50, axis=0)
    lower = np.percentile(values, 2.5, axis=0)    

    # Add the solid line and 
    axis.plot(dates, median, linewidth=5, linestyle=style, color=color, label=label)
    color = scale_luminosity(axis.lines[-1].get_color(), 1)
    axis.fill_between(dates, lower, upper, alpha=0.5, facecolor=color)
    
    axis.set_xlim([min(dates), max(dates)])
    axis.xaxis.set_major_formatter(matplotlib.dates.DateFormatter('%b'))


if __name__ == '__main__':
    main()