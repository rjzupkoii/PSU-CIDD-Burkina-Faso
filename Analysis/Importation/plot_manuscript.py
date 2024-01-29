#!/usr/bin/env python3

##
# plot_fig3.py
#
# Generate the Figure Three plot for the Burkina Faso 580Y importation manuscript.
#
# REMARKS Population immunity effect figure.
##
import datetime
import math
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
import numpy as np
import os
import pandas as pd
import sys

# From the PSU-CIDD-MaSim-Support repository
sys.path.insert(1, '../../../PSU-CIDD-MaSim-Support/Python/include')
from plotting import scale_luminosity


def make_figure(parameters):
    dates, data = prepare('data/denovo', parameters['variables'])
    plot(parameters, dates, data)


def prepare(path, variables, start = -61, end = -24):    
    # Build the dictionary that will be used to store the data
    dates, data = [], {}
    for key in variables:
        data[key] = []

    # Scan the directory for each file
    ndx = 0
    for file in os.scandir(path):
        replicate = pd.read_csv(file)
        replicate = replicate[replicate['DaysElapsed'] > (365 * 11)]
        for key in variables:
            data[key].append([])

        if len(dates) == 0:
            dates = replicate['DaysElapsed'].unique().tolist()
            dates = dates[start:end]
        for date in dates:
            byDate = replicate[replicate['DaysElapsed'] == date]
            for key in variables:
                if key == 'MOI':
                    # MOI = (Clones - (Clones - Infections)) / Multiclonal
                    clones = sum(byDate['ParasiteClones'])
                    infections = sum(byDate['InfectedIndividuals'])
                    multiclonal = sum(byDate['Multiclonal'])
                    data[key][ndx].append((clones - (clones - infections)) / multiclonal)                  
                elif key == 'Phi':
                    data[key][ndx].append(sum(byDate['ClinicalIndividuals']) / sum(byDate['InfectedIndividuals']))
                elif key == 'MeanTheta':
                    data[key][ndx].append(np.mean(byDate['MeanTheta']))
                elif key.startswith('580YProportion'):
                    data[key][ndx].append(sum(byDate['580yMulticlonal']) / sum(byDate['Multiclonal']))                    
                elif key == 'ClinicalCoverage':
                    data[key][ndx].append(sum(byDate['Treatments']) / sum(byDate['ClinicalIndividuals']))
                elif key == 'PhiCoverage':
                    phi = sum(byDate['ClinicalIndividuals']) / sum(byDate['InfectedIndividuals'])
                    coverage = sum(byDate['Treatments']) / sum(byDate['ClinicalIndividuals'])
                    data[key][ndx].append(phi * coverage)
                else:
                    data[key][ndx].append(math.log10(sum(byDate[key])))
    
        # Update the replicate count
        ndx += 1

    # Print some data and return the results
    print('Replicates: {}'.format(ndx))
    print_results(data)
    return dates, data


def print_results(data):
    for key in data.keys():
      initial = np.min(data[key])
      final = np.max(data[key])
      relative_change = (abs(final - initial ) / initial) * 100.0
      print('{}: {:.4f} - {:.4f}, {:.2f}%'.format(key, np.min(data[key]), np.max(data[key]), relative_change))


def plot(parameters, dates, data):
    # Internal function to actually generate the plot
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
    
    # Set constants, unpack the parameters
    STUDYDATE = '2007-01-01'
    color = parameters['colors']
    label = parameters['labels']
    style = parameters['styles']
        
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
    for key in parameters['left.keys']:
        add_plot(left, dates, data[key], next(color), next(label), style=next(style))
    for key in parameters['right.keys']:
        add_plot(right, dates, data[key], next(color), next(label), style=next(style))
    
    # Set the left y-axis label and tick values
    left.set_ylabel(parameters['left.ylabel'])
    left.set_ylim([0, 0.5])
    ticks = left.get_yticks()
    left.set_yticks(ticks)
    ticks = ['{:.1f}'.format(value) for value in ticks]
    ticks[0] = ''
    left.set_yticklabels(ticks)
    
    # Set the right y-axis label and tick values
    right.set_ylabel(parameters['right.ylabel'])
    if parameters['right.formatter'] != None:
        right.yaxis.set_major_formatter(parameters['right.formatter'])
        
    # Set the x label, legend
    left.set_xlabel('Month')
    left_lines, left_labels = left.get_legend_handles_labels()
    right_lines, right_labels = right.get_legend_handles_labels()
    left.legend(left_lines + right_lines, left_labels + right_labels, loc='lower center', frameon=False)
        
    # Save the plot
    if '.svg' in parameters['filename']:
        fig.savefig(parameters['filename'], format='svg')
    else:
        fig.tight_layout()
        fig.savefig(parameters['filename'], dpi=150)        
    fig.clear()
    

if __name__ == '__main__':
    os.makedirs('out', exist_ok=True)

    SUP_FIGURE_S5 = {
        'filename'      : 'out/ESM Fig. S5 - BFA, Treatment Coverage.png',

        'variables'     : ['Phi', 'MeanTheta', 'ClinicalCoverage'],
        'labels'        : iter([r'$\varphi$', r'$\theta_{pop}$', 'Treatment Coverage']),
        'colors'        : iter(['#332288', '#88CCEE', '#CC6677']),
        'styles'        : iter(['-', '-', '--']),

        'left.keys'     : ['Phi', 'MeanTheta'],
        'left.ylabel'   : r'$\varphi$ / $\theta_{pop}$',

        'right.keys'    : ['ClinicalCoverage'],
        'right.ylabel'  : 'Treatment Coverage of Clinical Cases',
        'right.formatter' : mtick.PercentFormatter(1.0, decimals=0)
    }
    make_figure(SUP_FIGURE_S5)
    
    FIGURE_SIX = {
        'filename'        : 'out/Fig. 6 - BFA, Phi-Coverage.png',
        
        'variables'       : ['Phi', 'PhiCoverage', 'ClinicalCoverage'],
        'labels'          : iter([r'$\varphi$', r'$\varphi \cdot Coverage$', 'Coverage']),
        'colors'          : iter(['#0000FF', '#000000', '#88CCEE']),
        'styles'          : iter(['--', '-', '--']),
        
        'left.keys'       : ['Phi', 'PhiCoverage'],
        'left.ylabel'     : r'$\varphi$ / $\varphi \cdot Coverage$',
        
        'right.keys'      : ['ClinicalCoverage'],
        'right.ylabel'    : 'Treatment Coverage of Clinical Cases',
        'right.formatter' :  mtick.PercentFormatter(1.0, decimals=0)
    }
    make_figure(FIGURE_SIX)

    FIGURE_SEVEN = {
        'filename'        : 'out/Fig. 7 - BFA, MOI.png',
        
        'variables'       : ['580YProportion', 'MOI'],
        'labels'          : iter(['Ratio of Multiclonal with 580Y vs. All Mulitclonal', 'Multiplicity of Infection']),
        'colors'          : iter(['#DDCC77', '#CC6677']),
        'styles'          : iter(['-', '--']),
        
        'left.keys'       : ['580YProportion'],
        'left.ylabel'     : 'Multiclonal Ratio',
        
        'right.keys'      : ['MOI'],
        'right.ylabel'    : 'Multiplicity of Infection',
        'right.formatter' : None
    }
    make_figure(FIGURE_SEVEN)

    