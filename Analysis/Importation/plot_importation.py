#!/usr/bin/env python3

import datetime
from operator import contains
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
CLINICAL_PROBABILITY, MIDPOINT, IMMUNE_EFFECT = 0.99, 0.15, 4.5

COLUMN, PARTNER, YLABEL = 0, 1, 2  
REPORT_LAYOUT = {
    'clinical' : ['ClinicalIndividuals', None, 'Clinical Cases, per 1000'],
    'clones' : ['Multiclonal', None, 'Multiclonal, per 1000'],
    'failures' : ['TreatmentFailure', None, 'Failures, per 1000'],    
    'frequency' : ['MARKER', 'theta', '580Y Frequency'],
    'infections' : ['InfectedIndividuals', None, 'Infections, per 1000'],
    'newinfections' : ['NewInfections', None, 'New Infections, per 1000'],
    'phi' : ['MARKER', None, 'Phi'],
    'symptoms' : ['MARKER', None, 'Probability of Symptoms'],
    'theta' : ['Theta', None, 'Theta'],
    'treatments' : ['Treatments', None, 'Treatments, per 1000'],
    'unweighted' : ['508yUnweighted', None, '580Y Clone Count'],

    # 'clinical-phi' : ['ClinicalIndividuals', 'treatments', 'Clinical Cases, per 1000'],
    'clinical-theta' : ['ClinicalIndividuals', 'theta', 'Clinical Cases, per 1000'],
    'clinical-failures' : ['ClinicalIndividuals', 'failures', 'Clinical Cases, per 1000'],
    # 'failures-phi' : ['TreatmentFailure', 'phi', 'Failures, per 1000'],
    'infections-failures' : ['InfectedIndividuals', 'failures', 'Infections, per 1000'],
    # 'infections-clones' : ['InfectedIndividuals', 'clones', 'Infections, per 1000'],
    # 'symptoms-failures' : ['MARKER', 'failures', 'Probability of Symptoms'],
    # 'symptoms-phi' : ['MARKER', 'phi', 'Probability of Symptoms'],
    # 'symptoms-treatments' : ['MARKER', 'treatments', 'Probability of Symptoms'],
    'treatments-theta' : ['Treatments', 'theta', 'Treatments, per 1000'],
    'unweighted-clones' : ['508yUnweighted', 'clones', '580Y Clone Count'],
    'unweighted-failures' : ['508yUnweighted', 'failures', '580Y Clone Count'],
    # 'unweighted-infections' : ['508yUnweighted', 'infections', '580Y Clone Count'],
    # 'unweighted-newinfections' : ['508yUnweighted', 'newinfections', '580Y Clone Count'],
    # 'unweighted-phi' : ['508yUnweighted', 'phi', '580Y Clone Count'],
    # 'unweighted-symptoms' : ['508yUnweighted', 'symptoms', '580Y Clone Count'],
    # 'unweighted-theta' : ['508yUnweighted', 'theta', '580Y Clone Count'],
    # 'unweighted-treatments' : ['508yUnweighted', 'treatments', '580Y Clone Count']    
}

ZONES = ['Sahelian (3 month)', 'Sudano-Sahelian (4 month)', 'Sudanian (5 month)']

PATH, OUTPUT, TITLE = 0, 1, 2
REPORTS = {
    'denovo' : ['data/denovo', 'denovo', 'De Novo Mutation'],
    'high' : ['data/hightransmission', 'high', 'High Transmission Importation'],
    'low' : ['data/lowtransmission', 'low', 'Low Transmission Importation']
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
    replicates = 0
    for file in os.scandir(path):
        data = pd.read_csv(file)
        data = data[data['DaysElapsed'] > (365 * 11)]
        
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
                # Prepare the row value
                if key.startswith('clinical'):
                    row = byZone['ClinicalIndividuals'] / (byZone['Population'] / 1000.0)
                elif key.startswith('clones'):
                    row = byZone['Multiclonal'] / (byZone['InfectedIndividuals'] / 1000.0)
                elif key.startswith('failures'):
                    row = byZone['TreatmentFailure'] / (byZone['Treatments'] / 1000.0)
                elif key.startswith('frequency'):
                    row = byZone['580yWeighted'] / byZone['InfectedIndividuals']
                elif key.startswith('infections'):
                    row = byZone['InfectedIndividuals'] / (byZone['Population'] / 1000.0)
                elif key.startswith('newinfections'):
                    row = byZone['NewInfections'] / (byZone['Population'] / 1000.0)                    
                elif key.startswith('phi'):
                    row = byZone['ClinicalIndividuals'] / byZone['InfectedIndividuals']
                elif key.startswith('symptoms'):
                    # isf.max_clinical_probability / (1 + pow((immune / isf.midpoint), isf.immune_effect_on_progression_to_clinical)
                    row = CLINICAL_PROBABILITY / (1 + pow((byZone['Theta'] / MIDPOINT), IMMUNE_EFFECT))
                elif key.startswith('treatments'):
                    row = byZone['Treatments'] / (byZone['InfectedIndividuals'] / 1000.0)
                else:        
                    row = byZone[REPORT_LAYOUT[key][COLUMN]].to_numpy()
                    
                # Add or append the row
                if len(zoneData[zone][key]) != 0:
                    zoneData[zone][key] = np.vstack((zoneData[zone][key], row))
                else:
                    zoneData[zone][key] = row
        
        # Update the replicate count
        replicates += 1

    # Return the results
    print('Replicates: {}'.format(replicates))
    return dates, zoneData


def report(dates, data, title, out):
    # Prepare the date format
    startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
    dates = [startDate + datetime.timedelta(days=x) for x in dates]

    # Load plot settings
    matplotlib.rc_file('../../Plots/matplotlibrc-line')

    count = 0
    for key in REPORT_LAYOUT:
        if '-' in key:
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