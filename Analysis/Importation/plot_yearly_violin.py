#!/usr/bin/env python3

# plot_yearly_violin.py
#
# This script generates a yearly summary violin plot.
import matplotlib.pyplot as plt
import numpy as np

from matplotlib import rc_file

# Note the output filename
IMAGEFILE = 'out/bfa_yearly_figure.png'

# Note the common properties
COLOR = ['#67a9cf', '#ef8a62']
MARKER_COLOR = ['#0571b0', '#ca0020']
SYMPTOMATIC_LABEL = ['Asymptomatic', 'Symptomatic']

# Prepare the figure to work with
rc_file('include/matplotlibrc-violin')
fig, axs = plt.subplots(nrows=1, ncols=2, sharey=True, sharex=True)

for symptomatic in [0, 1]:
    # Load the frequency data for the scenario
    data = []
    for frequency in [3, 6, 9]:
        filename = "intermediate/year-frequency-{}-symptomatic-{}.csv".format(frequency, symptomatic)
        working = np.genfromtxt(filename, delimiter=',')
        data.append(working)

    # Select our plot and add the data
    ax = axs.flat[symptomatic]
    vp = ax.violinplot(data, positions=range(3), showextrema=False)

    # Calculate the IQRs
    medians = []
    quartile = [[],[]]
    for values in data:
        q1, median, q3 = np.percentile(values, [25, 50, 75])
        medians.append(median)
        quartile[0].append(q1)
        quartile[1].append(q3)

    # Add the median and IQRs
    ax.scatter(range(3), medians, s=121, c=MARKER_COLOR[symptomatic], marker=".")
    ax.vlines(range(3), quartile[0], quartile[1], color=MARKER_COLOR[symptomatic])    

    # Parse the filename to get the imporation rate and symptomatic status, set the title
    ax.set_title(SYMPTOMATIC_LABEL[symptomatic])
    ax.set_xticks(range(3))
    ax.set_xticklabels([3, 6, 9])

    # Set the body color
    for body in vp['bodies']:
        body.set_facecolor(COLOR[symptomatic])

    # Set the axis labels
    if symptomatic == 0:
        ax.set_ylabel('580Y Frequency')
    ax.set_xlabel('Importation Frequency')          

# Save the figure to disk
if IMAGEFILE.endswith('tif'):
    fig.savefig(IMAGEFILE, dpi=300, format="tiff", pil_kwargs={"compression": "tiff_lzw"})
else:
    fig.savefig(IMAGEFILE)