#!/usr/bin/env python3

import datetime
import numpy as np
import os
import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
import sys

# From the PSU-CIDD-MaSim-Support repository
sys.path.insert(1, '../../../PSU-CIDD-MaSim-Support/Python/include')
from plotting import scale_luminosity
from utility import progressBar

STUDYDATE = '2007-01-01'

COLUMN, PARTNER, YLABEL = 0, 1, 2  
REPORT_LAYOUT = {
    'clones-theta' : ['Multiclonal', 'theta', 'Multiclonal Infections'],
    'clones-failures' : ['Multiclonal', 'failures', 'Multiclonal Infections'],
    'clones-frequency' : ['Multiclonal', 'frequency', 'Multiclonal Infections'],
    'failures' : ['TreatmentFailure', None, 'Treatment Failures'],
    'failures-theta' : ['TreatmentFailure', 'theta', 'Treatment Failures'],
    'infections' : ['InfectedIndividuals', None, 'Infected Individuals'],
    'theta' : ['Theta', None, 'Theta'],
    'treatments': ['Treatments', None, 'Treatments'],
    'frequency' : ['MARKER', 'theta', '580Y Frequency'],
    'unweighted' : ['508yUnweighted', None, '580Y Clone Count']
}

ZONES = ['Sahelian (3 month)', 'Sudano-Sahelian (4 month)', 'Sudanian (5 month)']

PATH, OUTPUT, TITLE = 0, 1, 2
REPORTS = {
    'high' : ['data/high-transmission', 'high', 'High Transmission Importation'],
    'low' : ['data/low-transmission', 'low', 'Low Transmission Importation']
}

def main():
    for key in REPORTS:
        print(REPORTS[key][TITLE])
        dates, data = prepare(REPORTS[key][PATH])
        report(dates, data, REPORTS[key][TITLE], REPORTS[key][OUTPUT])

def prepare(path):
    # Build the dictionary that will be used to store the data
    dates, zoneData = [], {}
    for zone in range(3):
        zoneData[zone] = {}
        for key in REPORT_LAYOUT:
            zoneData[zone][key] = []

    # Scan the directory for each file
    for file in os.scandir(path):
        data = pd.read_csv(file)
        data = data[data['DaysElapsed'] > (365 * 11)]

        print(data)
        
        if len(dates) == 0:
            dates = data['DaysElapsed'].unique().tolist()
        else:
            # TODO Remove this once all of the replicates are done
            check = data['DaysElapsed'].unique().tolist()
            if len(check) != len(dates):
                continue

        for zone in range(3):
            byZone = data[data['ClimaticZone'] == zone]
            for key in REPORT_LAYOUT:
                if key != 'frequency':
                    row = np.transpose(byZone[REPORT_LAYOUT[key][COLUMN]])
                    if len(zoneData[zone][key]) != 0:
                        zoneData[zone][key] = np.vstack((zoneData[zone][key], row))
                    else:
                        zoneData[zone][key] = row
                else:        
                    frequency = byZone['580yWeighted'] / byZone['InfectedIndividuals']
                    if len(zoneData[zone][key]) != 0:
                        zoneData[zone][key] = np.vstack((zoneData[zone][key], frequency))
                    else:
                        zoneData[zone][key] = frequency

    # Return the results
    return dates, zoneData


def report(dates, data, title, out):
    # Prepare the date format
    startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
    dates = [startDate + datetime.timedelta(days=x) for x in dates]

    # Load plot settings
    matplotlib.rc_file('../../Plots/matplotlibrc-line')

    replicates = len(data[0])
    print('Replicates: {}'.format(len(data[0])))

    count = 0
    for key in REPORT_LAYOUT:
        figure, axes = plt.subplots(3, 1)
        for zone in range(3):
            # Add the base plot
            add_plot(axes[zone], dates, data[zone][key], REPORT_LAYOUT[key][YLABEL], '#0571b0')

            # Add the partner plot if one is provided
            if REPORT_LAYOUT[key][PARTNER] != None:
                partner = REPORT_LAYOUT[key][PARTNER]
                add_plot(axes[zone].twinx(), dates, data[zone][partner], REPORT_LAYOUT[partner][YLABEL], '#ca0020')

            # Set the subplot title
            axes[zone].title.set_text(ZONES[zone])

        # Format the overall plot
        figure.suptitle(title)

        # Save the report
        os.makedirs('plots', exist_ok=True)
        plt.savefig('plots/{}-{}.png'.format(out, key))
        plt.close()

        # Update the progress bar
        count += 1
        progressBar(count, len(REPORT_LAYOUT))


def add_plot(axis, dates, values, ylabel, color):
    # Generate the percentiles
    upper = np.percentile(values, 97.5, axis=0)
    median = np.percentile(values, 50, axis=0)
    lower = np.percentile(values, 2.5, axis=0)

    # Add the data to the subplot
    axis.plot(dates, median, color=color)
    color = scale_luminosity(axis.lines[-1].get_color(), 1)
    axis.fill_between(dates, lower, upper, alpha=0.5, facecolor=color)

    # Label the axis
    axis.set_ylabel(ylabel, color=color)


if __name__ == '__main__':
    main()