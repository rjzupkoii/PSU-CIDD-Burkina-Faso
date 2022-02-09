#!/usr/bin/env python3

##
# plot_importation.py
#
# This Python script is used to generate the analysis and final manuscript plots
# for the importation study.
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
from utility import progressBar


# Study paramters
STUDYDATE = '2007-01-01'
CLINICAL_PROBABILITY, MIDPOINT, IMMUNE_EFFECT = 0.99, 0.15, 4.5

# Constants related to the report generation
ANALYSIS_FORMAT = '../../Plots/matplotlibrc-line'
MANUSCRIPT_FORMAT = 'matplotlibrc-line'
PRIMARY, SECONDARY = '#0571b0', '#ca0020'

# TODO Figure out how to sync the y-limits without needing to hard code them
YLIMIT, YYLIMIT = 0, 1
FINAL_REPORTS = {
    'multiclonal-moi': [[31, 80], [2.7, 3.8]],
    'unweighted-clinical' : [[], []],
    'unweighted-theta' : [[], []]
}

COLUMN, PARTNER, YLABEL = range(3)
REPORT_LAYOUT = {
    # Single reports that are used for analysis or in the final reports
    'clinical' : ['ClinicalIndividuals', None, 'Clinical Cases, per 1000'],
    'failures' : ['TreatmentFailure', None, 'Treatment Failures'], 
    'frequency' : ['MARKER', None, '580Y Frequency'],
    'infections' : ['InfectedIndividuals', None, 'Infections, per 1000'],
    'moi' : ['MARKER', None, 'Multiplicity of Infection'],
    'multiclonal' : ['Multiclonal', None, 'Prevalence of Multiclonal Infections'],
    'newinfections' : ['NewInfections', None, 'New Infections, per 1000'],
    'phi' : ['MARKER', None, 'Phi'],
    'symptoms' : ['MARKER', None, 'Probability of Symptoms'],
    'theta' : ['Theta', None, 'Theta'],
    'treatments' : ['Treatments', None, 'Treatments'],
    'unweighted' : ['508yUnweighted', None, '580Y Clone Count'],

    # Overlay reports used in the analysis
    'clinical-symptoms' : ['ClinicalIndividuals', 'symptoms', 'Clinical Cases, per 1000'],
    'newinfections-symptoms' : ['NewInfections', 'symptoms', 'New Infections'],
    'theta-moi' : ['Theta', 'moi', 'Theta'],
}

ZONES = ['Sahelian (3 month)', 'Sudano-Sahelian (4 month)', 'Sudanian (5 month)']

DATA_PATH, PLOT_OUTPUT, TITLE, FINAL_COLUMN = range(4)
DATA_SETS = {
    'denovo' : ['data/denovo', 'denovo', 'De Novo Mutation', 0],
    'low' : ['data/lowtransmission', 'low', 'Low Transmission Importation', 1],
    'high' : ['data/hightransmission', 'high', 'High Transmission Importation', 2]
}

def main():
    aggregate_data, aggregate_dates = {}, {}
    for key in DATA_SETS:
        print(DATA_SETS[key][TITLE])
        dates, data = prepare(DATA_SETS[key][DATA_PATH])
        working_reports(dates, data, DATA_SETS[key][TITLE], DATA_SETS[key][PLOT_OUTPUT])

        # Update the aggregate data sets
        aggregate_data[key] = data
        aggregate_dates[key] = dates
        
    print('Generating final reports...')
    final_reports(aggregate_dates, aggregate_data)


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
                elif key.startswith('frequency'):
                    row = byZone['580yWeighted'] / byZone['InfectedIndividuals']
                elif key.startswith('infections'):
                    row = byZone['InfectedIndividuals'] / (byZone['Population'] / 1000.0)
                elif key.startswith('multiclonal'):
                    row = (byZone['Multiclonal'] / byZone['InfectedIndividuals']) * 100.0
                elif key.startswith('moi'):
                    row = (byZone['ParasiteClones'] - (byZone['InfectedIndividuals'] - byZone['Multiclonal'])) / byZone['Multiclonal']
                elif key.startswith('phi'):
                    row = byZone['ClinicalIndividuals'] / byZone['InfectedIndividuals']
                elif key.startswith('symptoms'):
                    row = CLINICAL_PROBABILITY / (1 + pow((byZone['Theta'] / MIDPOINT), IMMUNE_EFFECT))
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


def final_reports(aggregate_dates, aggregate_data):
    # Load plot settings
    matplotlib.rc_file(MANUSCRIPT_FORMAT)

    count = 0
    for key in FINAL_REPORTS:
        primary, secondary = key.split('-')
        figure, axes = plt.subplots(3, 3)

        for study in DATA_SETS:
            # Prepare the date format
            startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
            dates = aggregate_dates[study]
            dates = [startDate + datetime.timedelta(days=x) for x in dates]

            # Grab the column we are working with
            column = DATA_SETS[study][FINAL_COLUMN]

            for zone in range(3):
                # Add the main plot, and ylabel if we are in the right spot
                add_plot(axes[zone, column], dates, aggregate_data[study][zone][primary], PRIMARY)
                axes[zone, column].tick_params(axis='y', colors=PRIMARY)
                
                # Add the overlay plot, set the tick colors, label if in the right location
                overlay = axes[zone, column].twinx()
                add_plot(overlay, dates, aggregate_data[study][zone][secondary], SECONDARY)
                overlay.tick_params(axis='y', colors=SECONDARY)
                if column == 2 and zone == 1:
                    overlay.set_ylabel(REPORT_LAYOUT[secondary][YLABEL], color=SECONDARY)

                # Set the subplot title
                if zone == 0:
                    axes[zone, column].title.set_text('{}\n{}'.format(DATA_SETS[study][TITLE], ZONES[zone]))
                else:
                    axes[zone, column].title.set_text(ZONES[zone])

            # Add the primary, secondary y-label
            axes[1, 0].set_ylabel(REPORT_LAYOUT[primary][YLABEL], color=PRIMARY)

        # Apply the general formatting to the plot
        for ax in axes.flat:
            ax.set_xlim([min(dates), max(dates)])

            # Are we maniplating the y-tick labels?
            if max(ax.get_yticks().tolist()) > 1000:
                values, ticks = [], []
                for tick in ax.get_yticks().tolist():
                    if tick >= 500:
                        ticks.append('%.1fK' % (tick / 1000))
                    elif tick >= 0:
                        ticks.append(str(tick))
                    if tick >= 0:
                        values.append(tick)

                # Let Matplotlib know we are keeping the same ticks bound before setting the labels
                ax.set_yticks(values)
                ax.set_yticklabels(ticks)

            else:
                if len(FINAL_REPORTS[key][YLIMIT]) != 0:
                    ax.set_ylim(FINAL_REPORTS[key][YLIMIT])
                if len(FINAL_REPORTS[key][YYLIMIT]) != 0:
                    ax.get_shared_x_axes().get_siblings(ax)[0].set_ylim(FINAL_REPORTS[key][YYLIMIT])

        # Save the report
        os.makedirs('plots/manuscript', exist_ok=True)
        plt.savefig('plots/manuscript/{}.png'.format(key))
        plt.close()

        # Update the progress bar
        count += 1
        progressBar(count, len(FINAL_REPORTS))


def working_reports(dates, data, title, out):
    # Prepare the date format
    startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
    dates = [startDate + datetime.timedelta(days=x) for x in dates]

    # Load plot settings
    matplotlib.rc_file(ANALYSIS_FORMAT)

    count = 0
    for key in REPORT_LAYOUT:
        figure, axes = plt.subplots(3, 1)
        for zone in range(3):
            # Add the base plot
            add_plot(axes[zone], dates, data[zone][key], PRIMARY)

            # Add the partner plot if one is provided
            if REPORT_LAYOUT[key][PARTNER] != None:
                partner = REPORT_LAYOUT[key][PARTNER]
                add_plot(axes[zone].twinx(), dates, data[zone][partner], SECONDARY)

            if zone == 1:
                axes[zone].set_ylabel(REPORT_LAYOUT[key][YLABEL], color=PRIMARY)
                if REPORT_LAYOUT[key][PARTNER] != None:
                    axes[zone].get_shared_x_axes().get_siblings(axes[zone])[0].set_ylabel(REPORT_LAYOUT[partner][YLABEL], color=SECONDARY)

            # Set the subplot title
            axes[zone].title.set_text(ZONES[zone])

        # Set the x,y-limits
        for ax in axes.flat:
            ax.set_xlim([min(dates), max(dates)])

        # Format the overall plot
        figure.suptitle(title)

        # Save the report
        os.makedirs('plots/analysis/{}'.format(out), exist_ok=True)
        plt.savefig('plots/analysis/{}/{}.png'.format(out, key))
        plt.close()

        # Update the progress bar
        count += 1
        progressBar(count, len(REPORT_LAYOUT))


def add_plot(axis, dates, values, color):
    # Generate the percentiles
    upper = np.percentile(values, 97.5, axis=0)
    median = np.percentile(values, 50, axis=0)
    lower = np.percentile(values, 2.5, axis=0)

    # Add the data to the subplot
    axis.plot(dates, median, color=color)
    color = scale_luminosity(axis.lines[-1].get_color(), 1)
    axis.fill_between(dates, lower, upper, alpha=0.5, facecolor=color)


if __name__ == '__main__':
    main()