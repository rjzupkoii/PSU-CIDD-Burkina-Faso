#!/usr/bin/env python3

##
# plot_importation.py
#
# This Python script is used to generate the analysis and final manuscript plots
# for the importation study.
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
from utility import progressBar


# Study paramters
STUDYDATE = '2007-01-01'
CLINICAL_PROBABILITY, MIDPOINT, IMMUNE_EFFECT = 0.99, 0.15, 4.5

# Constants related to the report generation
ANALYSIS_FORMAT = '../../Plots/matplotlibrc-line'
MANUSCRIPT_FORMAT = 'matplotlibrc-line'
 
# Color scheme for final reprots based on Tol (https://personal.sron.nl/~pault/#sec:qualitative)
# 1. 580Ymulticlonal : #882255
# 2. clinical : #332288
# 3. multiclonal : #117733
# 4. moi : #88CCEE
# 5. proportion : #CC6677
# 6. theta : #44AA99
# 7. treatments : #7570b3
# 8. unweighted : #AA4499
PRIMARY, SECONDARY = range(2)
NINE_PANEL = {
    # Manuscript, primary
    'proportion580Y-treatments' : ['#663333', '#225555'],    

    # Manuscript, secondary

    # Supplemental plots
    'frequency-' : ['#555555', ''],
    'theta-' : ['#555555', ''],

    # Other plots
    '580Ymulticlonal-proportion' : ['#882255', '#CC6677'],
    '580Ymulticlonal-treatments' : ['#882255', '#7570b3'],
    'infections-clinical' : ['#663333', '#332288'],
    'moi-proportion' : ['#663333', '#332288'],
    'multiclonal-moi': ['#117733', '#88CCEE'],
    'proportion580Y-multiclonal' : ['#663333', '#225555'],    
    'proportion-treatments' : ['#CC6677', '#7570b3'],
    'ratio-treatments' : ['#663333', '#7570b3'],    
    'theta-phi' : ['#117733', '#88CCEE'],
    'theta-symptoms' : ['#117733', '#88CCEE'],
    'theta-treatments' : ['#44AA99', '#7570b3'],
    'weighted-phi' : ['#117733', '#88CCEE'],
    'weighted-symptoms' : ['#117733', '#88CCEE'],
    'weighted-theta' : ['#117733', '#88CCEE'],
    'unweighted-580Ymulticlonal' : ['#AA4499', '#882255'],
    'unweighted-clinical' : ['#AA4499', '#332288' ],
    'unweighted-theta' : ['#AA4499', '#44AA99'],
    'unweighted-treatments' : ['#AA4499', '#7570b3'],
}

COLUMN, PARTNER, YLABEL = range(3)
REPORT_LAYOUT = {
    # Single metric reports
    '580Ymulticlonal' : ['580yMulticlonal', None, '580Y Multiclonal Infections'],
    'clinical' : ['ClinicalIndividuals', None, 'Clinical Cases, per 1000'],
    'failures' : ['TreatmentFailure', None, 'Treatment Failures'], 
    'frequency' : ['MARKER', None, '580Y Frequency'],
    'infections' : ['InfectedIndividuals', None, 'Infections, per 1000'],
    'moi' : ['MARKER', None, 'Multiplicity of Infection'],
    'multiclonal' : ['Multiclonal', None, 'Prevalence of Multiclonal Infections'],
    'newinfections' : ['NewInfections', None, 'New Infections'],
    'phi' : ['MARKER', None, 'Phi (Clinical / Infected)'],
    'proportion' : ['MARKER', None, 'Proportion of 580Y Multiclonal Infections'],
    'proportion580Y' : ['MARKER', None, 'Proportion 580Y of All Clones'],
    'ratio' : ['MARKER', None, 'Ratio of Weighted to Unweighted 580Y Clones'],
    'symptoms' : ['MARKER', None, 'Probability of Symptoms'],
    'theta' : ['MeanTheta', None, 'Theta (Population Mean)'],
    'treatments' : ['Treatments', None, 'Treatments'],
    'weighted' : ['580yWeighted', None, 'Weighted 580Y Clone Count'],
    'unweighted' : ['580yUnweighted', None, '580Y Clone Count'],

    # Overlay reports
    'clinical-symptoms' : ['ClinicalIndividuals', 'symptoms', 'Clinical Cases, per 1000'],
    'newinfections-symptoms' : ['NewInfections', 'symptoms', 'New Infections'],
    'theta-moi' : ['MeanTheta', 'moi', 'Theta'],
    'treatments-580Ymulticlonal' : ['Treatments', '580Ymulticlonal', 'Treatments'],
    'unweighted-580Ymulticlonal' : ['580yUnweighted', '580Ymulticlonal', '580Y Clone Count'],
}

ZONES = ['Sahelian (3 month)', 'Sudano-Sahelian (4 month)', 'Sudanian (5 month)']

DATA_PATH, PLOT_OUTPUT, TITLE, FINAL_COLUMN = range(4)
DATA_SETS = {
    'denovo' : ['data/denovo', 'denovo', 'De Novo Mutation', 0],
    'low' : ['data/lowtransmission', 'low', 'Low Transmission Importation', 1],
    'high' : ['data/hightransmission', 'high', 'High Transmission Importation', 2]
}

FIELDS, LABELS, TITLE, FILENAME = range(4)
COMPARISONS = [
    # Mechanism plots
    [['beta', 'newinfections', 'theta', 'symptoms'],
     ['Seasonal Beta Multiplier', 'New Infections', 'Theta (Population Mean)', 'Probability of Symptoms'],
     'Tranmission Driving Symptoms', 'transmission-symptoms'],
    [['newinfections', 'theta', 'symptoms', 'treatments'],
     ['New Infections', 'Theta (Population Mean)', 'Probability of Symptoms', 'Treatments'],
     'Probability of Symptoms Driving Treatments', 'symptoms-treatments'],
    [['newinfections', 'phi', 'unweighted', 'theta', 'symptoms', 'beta'],
     ['New Infections', 'Phi Ratio', 'Unweighted 580Y Clones', 'Theta (Population Mean)', 'Probability of Symptoms', 'Treatments'],
     '', 'basic-mechanism'],

    # Relationship between multiclonal infections and drug-resistant parasites
    [['newinfections', 'multiclonal', '580Ymulticlonal', 'proportion', 'treatments'],
     ['New Infections', 'Multiclonal Infections', 'Multiclonal 580Y Infections', 'Proportion of 580Y Multiclonal Infections', 'Treatments'],
     'Relationship between multiclonal infections and drug-resistant parasites', 'multiclonal vs. 580Y'],

    # Competitive release
    [['newinfections', 'proportion', 'unweighted', 'treatments'],
     ['New Infections', 'Proportion of 580Y Multiclonal Infections', 'Unweighted 580Y Clones', 'Treatments'],
     'Competitive Release', 'competitive release'],
    
    # Symptomatic cases -> treatments -> selective pressure for drug-resistance
    [['newinfections', 'symptoms', 'treatments', 'unweighted'],
     ['New Infections', 'Probability of Symptoms', 'Treatments', 'Unweighted 580Y Clones'],
     'Immune response driving selection pressure', 'symptomatic vs. 580Y'],

    # Non-580Y behavior
    [['beta', 'newinfections', 'multiclonal', 'clinical', 'treatments'],
     ['Seasonal Beta Multiplier', 'New Infections', 'Multiclonal Infections', 'Clinical Infections', 'Treatments'],
     'General Infection Behavior', 'general-behavior'],

    # 580Y behavior
    [['beta', 'unweighted', 'weighted', '580Ymulticlonal', 'treatments'],
     ['Seasonal Beta Multiplier', 'Unweighted 580Y Clones', 'Weighted 580Y Clones', 'Multiclonal 580Y Infection', 'Treatments'],
     '580Y Infection Behavior', '580Y-behavior'],
]

def main():
    aggregate_data, aggregate_dates = {}, {}
    for key in DATA_SETS:
        print(DATA_SETS[key][TITLE])
        dates, data = prepare(DATA_SETS[key][DATA_PATH])
        study_reports(dates, data, DATA_SETS[key][TITLE], DATA_SETS[key][PLOT_OUTPUT])

        # Update the aggregate data sets
        aggregate_data[key] = data
        aggregate_dates[key] = dates
        
    print('Generating nine panel reports...')
    nine_panel_reports(aggregate_dates, aggregate_data)

    print('Generating comparsion figures...')
    for ndx in range(len(COMPARISONS)):
        comparison_figure(aggregate_dates, aggregate_data, COMPARISONS[ndx][FIELDS], COMPARISONS[ndx][LABELS], COMPARISONS[ndx][TITLE], COMPARISONS[ndx][FILENAME])
        progressBar(ndx + 1, len(COMPARISONS))


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
                    # MOI = (Clones - (Clones - Infections)) / Multiclonal
                    row = (byZone['ParasiteClones'] - (byZone['ParasiteClones'] - byZone['InfectedIndividuals'])) / byZone['Multiclonal']
                elif key.startswith('phi'):
                    row = byZone['ClinicalIndividuals'] / byZone['InfectedIndividuals']
                elif key.startswith('proportion'):
                    row = byZone['580yMulticlonal'] / byZone['Multiclonal']
                elif key.startswith('proportion580Y'):
                    row = byZone['580yUnweighted'] / byZone['ParasiteClones']
                elif key.startswith('ratio'):
                    row = byZone['580yWeighted'] / byZone['580yUnweighted']
                elif key.startswith('symptoms'):
                    row = CLINICAL_PROBABILITY / (1 + pow((byZone['MeanTheta'] / MIDPOINT), IMMUNE_EFFECT))
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


def comparison_figure(aggregate_dates, aggregate_data, fields, labels, title, filename):
    STARTDATE, ENDDATE = -49, -24

    # Load plot settings
    matplotlib.rc_file(MANUSCRIPT_FORMAT)

    figure, axis = plt.subplots(3, 3)
    for study in DATA_SETS:
        # Prepare the date format
        startDate = datetime.datetime.strptime(STUDYDATE, "%Y-%m-%d")
        dates = aggregate_dates[study][STARTDATE:ENDDATE]
        dates = [startDate + datetime.timedelta(days=x) for x in dates]

        # Grab the column we are working with
        column = DATA_SETS[study][FINAL_COLUMN]
        for zone in range(3):
            # Reset the list of handles, this approach saves some mental overhead
            handles = []

            # Isolate the data for this zone
            data = aggregate_data[study][zone]

            for field in fields:
                # If we are rendering the beta, then use the seasonality adjustment as a proxy
                if field == 'beta':
                    handle, = axis[zone, column].plot(dates, beta_multiplier(zone, aggregate_dates[study][STARTDATE:ENDDATE]))

                # Otherwise just show the normalized data for the field of interest
                else:
                    upper, median, lower = normalize(data[field], STARTDATE, ENDDATE)
                    handle, = axis[zone, column].plot(dates, median)
                    color = scale_luminosity(axis[zone, column].lines[-1].get_color(), 1)
                    axis[zone, column].fill_between(dates, lower, upper, alpha=0.5, facecolor=color)
                handles.append(handle)

            # Set the subplot title
            if zone == 0:
                axis[zone, column].title.set_text('{}\n{}'.format(DATA_SETS[study][TITLE], ZONES[zone]))
            else:
                axis[zone, column].title.set_text(ZONES[zone])                        
    
    # Format the overall plot
    figure.suptitle(title)

    # Set the legend
    axis[2, 1].legend(handles=handles, labels=labels, loc='upper center', 
        bbox_to_anchor=(0.5, -0.2), frameon=False, fancybox=False, shadow=False, ncol=(int)(len(labels) / 2))

    # Format the plots
    for ax in axis.flat:
        ax.set_xlim([min(dates), max(dates)])        
        ax.xaxis.set_major_formatter(matplotlib.dates.DateFormatter('%b'))
        
    # Save the report
    plt.savefig('plots/manuscript/{}.png'.format(filename), bbox_inches='tight')
    plt.close()


# Seasonality of malaria in Burkina Faso
def beta_multiplier(zone, times):
    # sin+ calculation
    def sin_plus(value):
        result = math.sin(value)
        if result > 0: return result
        return 0

    # Sahelian zone (3 month)
    if zone == 0:
        base, a, b, phi = 0.4, 0.6, 2.5, 146

    # Sudano-Sahelian zone (4 month)
    elif zone == 1:
        base, a, b, phi = 0.4, 0.6, 2.3, 155

    # Sudanian zone (5 month)
    else:
        base, a, b, phi = 0.4, 0.6, 1.9, 155
    
    # Apply the beta scaling function and return the results
    results = []
    for days in times:
        time = int((datetime.datetime.strptime(STUDYDATE, '%Y-%m-%d') + datetime.timedelta(days=days)).strftime('%j'))
        results.append(base + (a * sin_plus(b * math.pi * (time - phi) / 365)))
    return results


def normalize(values, start, end):
    # Find the bounds
    upper = np.percentile(values, 75, axis=0)
    median = np.percentile(values, 50, axis=0)
    lower = np.percentile(values, 25, axis=0)

    # Clip to the range of interest
    upper = upper[start:end]
    median = median[start:end]
    lower = lower[start:end]

    # Return nothing if the upper bound is invalid
    if max(median) == 0: return [0]*abs(start-end), [0]*abs(start-end), [0]*abs(start-end)

    # Scale from zero to one and return
    high, low = max(median), min(median)
    upper = (upper - low) / (high - low)
    median = (median - low) / (high - low)
    lower = (lower - low) / (high - low)

    upper[upper > 1] = 1
    lower[lower < 0] = 0
    return upper, median, lower


def nine_panel_reports(aggregate_dates, aggregate_data):
    # Load plot settings
    matplotlib.rc_file(MANUSCRIPT_FORMAT)

    count = 0
    for key in NINE_PANEL:
        primary, secondary = key.split('-')
        primary_color, secondary_color = NINE_PANEL[key][PRIMARY], NINE_PANEL[key][SECONDARY]
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
                add_plot(axes[zone, column], dates, aggregate_data[study][zone][primary], primary_color)
                axes[zone, column].tick_params(axis='y', colors=primary_color)
                
                # Add the overlay plot, set the tick colors, label if in the right location
                if secondary is not '':
                    overlay = axes[zone, column].twinx()
                    add_plot(overlay, dates, aggregate_data[study][zone][secondary], secondary_color)
                    overlay.tick_params(axis='y', colors=secondary_color)
                    if column == 2 and zone == 1:
                        overlay.set_ylabel(REPORT_LAYOUT[secondary][YLABEL], color=secondary_color)

                # Set the subplot title
                if zone == 0:
                    axes[zone, column].title.set_text('{}\n{}'.format(DATA_SETS[study][TITLE], ZONES[zone]))
                else:
                    axes[zone, column].title.set_text(ZONES[zone])

            # Add the primary, secondary y-label
            axes[1, 0].set_ylabel(REPORT_LAYOUT[primary][YLABEL], color=primary_color)

        # Apply the general formatting to the plot
        for ax in axes.flat:
            # Set the x-axis limits
            ax.set_xlim([min(dates), max(dates)])

            # Only show every other year tick
            ax.set_xticks(ax.get_xticks().tolist()[::2])
            ax.xaxis.set_major_formatter(matplotlib.dates.DateFormatter('%Y'))

            # Format the y-axis ticks
            format_yticks(ax)
            format_yticks(ax.get_shared_x_axes().get_siblings(ax)[0])

        # Save the report
        os.makedirs('plots/manuscript', exist_ok=True)
        plt.savefig('plots/manuscript/{}.png'.format(key), bbox_inches='tight')
        plt.close()

        # Update the progress bar
        count += 1
        progressBar(count, len(NINE_PANEL))


def study_reports(dates, data, title, out):
    primary_color, secondary_color = '#555555', '#CC3311'

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
            add_plot(axes[zone], dates, data[zone][key], primary_color)

            # Add the partner plot if one is provided
            if REPORT_LAYOUT[key][PARTNER] != None:
                partner = REPORT_LAYOUT[key][PARTNER]
                add_plot(axes[zone].twinx(), dates, data[zone][partner], secondary_color)

            if zone == 1:
                axes[zone].set_ylabel(REPORT_LAYOUT[key][YLABEL], color=primary_color)
                if REPORT_LAYOUT[key][PARTNER] != None:
                    axes[zone].get_shared_x_axes().get_siblings(axes[zone])[0].set_ylabel(REPORT_LAYOUT[partner][YLABEL], color=secondary_color)

            # Set the subplot title
            axes[zone].title.set_text(ZONES[zone])

        # Set the limits and format the ticks
        for ax in axes.flat:
            ax.set_xlim([min(dates), max(dates)])
            format_yticks(ax)
            format_yticks(ax.get_shared_x_axes().get_siblings(ax)[0])            

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


def format_yticks(ax):
    yticks = ax.get_yticks().tolist()
    values, ticks = format_ticks(yticks)
    if values != None:
        ax.set_yticks(values)
        ax.set_yticklabels(ticks)   


if __name__ == '__main__':
    main()