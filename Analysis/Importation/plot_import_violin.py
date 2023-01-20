#!/usr/bin/env python3

# plot_import_violin.py
#
# Use the intermediate files from the MATLAB script frequency_stats.m to generate violin plots.
import math
import matplotlib
import matplotlib.pyplot as plt
import numpy as np

# Note the output filename
IMAGEFILE = 'plots/manuscript/bfa_summary_figure.png'

# Note the common properties
COLOR = ['#ef8a62', '#67a9cf']
MARKER_COLOR = ['#ca0020', '#0571b0']
SYMPTOMATIC_LABEL = ['Asymptomatic', 'Symptomatic']

# Prepare the figure to work with
matplotlib.rc_file('include/matplotlibrc-violin')
fig, axs = plt.subplots(nrows=4, ncols=2, sharey=True, sharex=True)
plot = 0

# Iterate over the primary combinations
for frequency in [1, 3, 6, 9]:
    for symptomatic in [0, 1]:

        # Load the data from disk and mask out the infinite values and NaN
        filename = "intermediate/final-frequency-{}-symptomatic-{}.csv".format(frequency, symptomatic)
        df = np.genfromtxt(filename, delimiter=',')
        df[df == -np.inf] = math.log10(math.pow(10, -8))
        mask = ~np.isinf(df) & ~np.isnan(df)
        data = [d[m] for d, m in zip(df.T, mask.T)]
        
        # Update our subplot index
        ax = axs.flat[plot]
        plot = plot + 1

        # Add the shaded region for the seasonal transmission, note we are zero indexed here
        # so 5 - June, 10 - November
        ax.axvspan(5, 10, alpha=0.2, color='#CCCCCC', zorder=0)

        # Add the violin plot
        vp = ax.violinplot(data, positions=range(12), showextrema=False)

        # Calculate the IQRs
        medians = []
        quartile = [[],[]]
        for values in data:
            q1, median, q3 = np.percentile(values, [25, 50, 75])
            medians.append(median)
            quartile[0].append(q1)
            quartile[1].append(q3)           
        
        # Add the median and IQRs
        index = int(plot % 2)
        ax.scatter(range(12), medians, s=121, c=MARKER_COLOR[index], marker=".")
        ax.vlines(range(12), quartile[0], quartile[1], color=MARKER_COLOR[index])

        # Parse the filename to get the importation rate and symptomatic status, set the title
        ax.set_title("{}/month, {}".format(frequency, SYMPTOMATIC_LABEL[symptomatic]))
        ax.set_xticks(range(12))
        ax.set_xticklabels(range(1, 13))

        # Set the body color
        for body in vp['bodies']:
            body.set_facecolor(COLOR[index])

        # Set the axis labels
        if plot % 2 == 1:
            ax.set_ylabel(r'580Y Frequency ($log_{10})$')
        if plot > 6:
            ax.set_xlabel('Month of Importation')

# Save the plot
fig.savefig('plots/manuscript/MS BFA, Fig. 1.png', dpi=150)
fig.savefig('plots/manuscript/MS BFA, Fig. 1.svg', format='svg')
