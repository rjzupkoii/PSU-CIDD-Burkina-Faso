#!/usr/bin/env python3

# plot_frequency.py
# 
# Plot the frequency data as a mean line plus a shaded IQR.
import colorsys
import datetime
import glob
import matplotlib.pyplot as plt 
import numpy as np
import pandas as pd
import sys

from matplotlib import rc_file


def iqr(data, range=[25, 75]):
    '''Calculate the interquartile range (IQR) of the dictionary of arrays provided
    
    Returns a matrix in which the first row is the first percentile and the second row is the second percentile'''
    results = [[], []]
    for key in data:
        q25, q75 = np.percentile(data[key], range)
        results[0].append(q25)
        results[1].append(q75)
    return results


def scale_luminosity(rgb, luminosity):
    '''Scale the given RGB color based upon the luminosity value provided'''
    if type(rgb) is str:
        rgb = rgb.lstrip('#')
        h, l, s = colorsys.rgb_to_hls(*tuple(int(rgb[i:i+2], 16)/255 for i in (0, 2, 4)))
    elif type(rgb) is tuple:
        h, l, s = colorsys.rgb_to_hls(*rgb)
    else:
        raise TypeError("Expected {}, got {}".format(str, type(rgb)))
    return colorsys.hls_to_rgb(h, min(1, l * luminosity), s)


def prepare(filter, genotypes):

    # Prepare the working data dictionary
    data = {}
    for genotype in genotypes.keys():
        data[genotype] = {}

    # Extract the frequency data that we care about
    replicates = 0
    dates = None
    for file in glob.glob(filter):
        # Read the file, prepare the dates if we haven't already
        temp = pd.read_csv(file)
        if dates is None:
            
            # Get the list of dates, clip the first one so that the plot is cleanly aligned with the y-axis
            # as opposed to having a blank space
            dates = temp.days.unique().tolist()
            dates = dates[1:]

            # Prepare the rest of the data structure
            for genotype in genotypes.keys():
                for date in dates:
                    data[genotype][date] = []

        # Filter by the genotypes we care about, 
        for genotype in genotypes.keys():
            df = temp[temp.name.str.contains(genotypes[genotype])]
            for date in dates:
                data[genotype][date].append(df[df.days == date].frequency.sum())

        # Update the progress
        replicates = replicates + 1
        sys.stdout.write("\rProcessed: {}".format(replicates),)
        sys.stdout.flush()

    print("\nDone!")
    return data, dates, replicates


def plot(studyDate, title, filename, data, dates, replicates, type='median', ylimit=None):

    # Based on Tol color palette
    colors = ['#DDCC77', '#882255', '#44AA99', '#332288' ]

    # Format the dates
    startDate = datetime.datetime.strptime(studyDate, "%Y-%m-%d")
    dates = [startDate + datetime.timedelta(days=x) for x in dates]

    # Format the plot
    rc_file("matplotlibrc-line")
    axes = plt.axes()
    axes.set_yscale('log')
    axes.set_xlim([min(dates), max(dates)])
    axes.set_title(title)
    axes.set_ylabel('Genotype Frequency')
    axes.set_xlabel('Model Year')

    # Generate the plot
    colorIndex = 0
    for genotype in data:

        # Find the plot line that we are generating
        if type == 'median':
            plotData = [np.median(x) for x in data[genotype].values()]
        elif type == 'mean':
            sums = [sum(x) for x in data[genotype].values()]
            sums = np.true_divide(sums, replicates)
        else:
            sys.stderr.write("Unknown plot type: {}".format(type))
            sys.exit(-1)

        # Plot the line and update the color index
        if ylimit is not None:
            plt.ylim(ylimit)
        plt.plot(dates, plotData, label=genotype, linewidth=2, color=colors[colorIndex])
        colorIndex += 1
        
        # Plot the 95% range around the plot line
        results = iqr(data[genotype], [2.5, 97.5])
        color = scale_luminosity(plt.gca().lines[-1].get_color(), 1)
        plt.fill_between(dates, results[0], results[1], alpha=0.5, facecolor=color)

    # Finalize the formatting and save
    plt.legend(frameon=False)
    # Save the figure to disk
    if filename.endswith('tif'):
        plt.savefig(filename, dpi=300, format="tiff", pil_kwargs={"compression": "tiff_lzw"})
    else:
        plt.savefig(filename)
    plt.close()
    print("Generated plot with {} line".format(type))
    if ylimit is not None: print("Used fixed y-axis limits")
    print("Saved as: {}".format(filename))


if __name__ == "__main__":
    genotypes = {
        'Plasmespin 2/3 double copy':r'......2',
        '580Y':r'.....Y.',
        'KNF':r'KNF....',
        'TNF':r'TNF....'}

    # Immediate AL/DP MFT and private market elimination
    intermediary = prepare('../Analysis/Loader/out/bfa-aldp-rapid/*-frequencies.csv', genotypes)
    plot('2007-01-01', 'Genotype Frequency with Immediate AL/DHA-PPQ MFT and Private Market Elimination', 'out/bfa-aldp-rapid-genotype-frequency.png', *intermediary)

    # Ten-year phase in of AL/DP MFT and private market elimination
    intermediary = prepare('../Analysis/Loader/out/bfa-aldp10-tenyear/*-frequencies.csv', genotypes)
    plot('2007-01-01', 'Genotype Frequency with Phased in AL/DHA-PPQ MFT and Private Market Elimination over 10 years', 'out/bfa-aldp10-tenyear-genotype-frequency.png', *intermediary) 

    # Sensitivity analysis
    intermediary = prepare('../Analysis/Loader/out/bfa-0.01983/*-frequencies.csv', genotypes)
    plot('2007-01-01', 'Genotype Frequency with Very Fast Mutation Rate (0.01983)', 'out/bfa-0.01983-genotype-frequency.png', *intermediary, ylimit=[pow(10, -8), pow(10, 0)])
    intermediary = prepare('../Analysis/Loader/out/bfa-0.009915/*-frequencies.csv', genotypes)
    plot('2007-01-01', 'Genotype Frequency with Fast Mutation Rate (0.009915)', 'out/bfa-0.009915-genotype-frequency.png', *intermediary, ylimit=[pow(10, -8), pow(10, 0)])
    intermediary = prepare('../Analysis/Loader/out/bfa-0.0003966/*-frequencies.csv', genotypes)
    plot('2007-01-01', 'Genotype Frequency with Slow Mutation Rate (0.0003966)', 'out/bfa-0.0003966-genotype-frequency.png', *intermediary, ylimit=[pow(10, -8), pow(10, 0)])
    intermediary = prepare('../Analysis/Loader/out/bfa-0.0001983/*-frequencies.csv', genotypes)
    plot('2007-01-01', 'Genotype Frequency with Very Slow Mutation Rate (0.0001983)', 'out/bfa-0.0001983-genotype-frequency.png', *intermediary, ylimit=[pow(10, -8), pow(10, 0)])

    # Figure for Keystone symposium
    intermediary = prepare('../Analysis/Loader/out/bfa-fast-no-asaq/*-frequencies.csv', genotypes)
    plot('2007-01-01', 'Burkina Faso, Drug Resistance Markers Under Status Quo Conditions', 'out/bfa-status-quo.png', *intermediary, ylimit=[pow(10, -8), pow(10, 0)])