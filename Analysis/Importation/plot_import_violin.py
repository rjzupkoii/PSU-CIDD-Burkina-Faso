#!/usr/bin/env python3

# plot_import_violin.py
#
# Use the intermediate files from the MATLAB script to generate violin plots.
import matplotlib.pyplot as plt
import numpy as np

from matplotlib import rc_file

# Note the output filename
IMAGEFILE = 'out/bfa_summary_figure.png'

# Note the common properties
COLORS = ['#1b9e77', '#d95f02']
SYMPTOMATIC_LABEL = ['Asymptomatic', 'Symptomatic']

# Prepare the figure to work with
rc_file('include/matplotlibrc-violin')
fig, axs = plt.subplots(nrows=2, ncols=3)
plot = 0

# Iterate over the primary combinations
for symptomatic in [0, 1]:
    for frequency in [3, 6, 9]:

        # Load the data from disk and mask out the infinate values and NaN
        filename = "intermediate/final-frequency-{}-symptomatic-{}.csv".format(frequency, symptomatic)
        df = np.genfromtxt(filename, delimiter=',')
        mask = ~np.isinf(df) & ~np.isnan(df)
        data = [d[m] for d, m in zip(df.T, mask.T)]
        
        # Update our subplot index
        ax = axs.flat[plot]
        plot = plot + 1

        # Add the violin plot
        vp = ax.violinplot(data, positions=range(12), showmedians=True, showextrema=True)

        # Parse the filename to get the imporation rate and symptomatic status, set the title
        ax.set_title("{}/month, {}".format(frequency, SYMPTOMATIC_LABEL[symptomatic]))
        ax.set_xticks(range(12))
        ax.set_xticklabels(range(1, 13))

        # Set the colors
        index = int(plot / 4)
        for part in ('cbars','cmins','cmaxes','cmeans', 'cmedians'):
            if part in vp:
                vp[part].set_edgecolor(COLORS[index])
        for body in vp['bodies']:
            body.set_facecolor(COLORS[index])

        # Update the median marker
        xy = [[l.vertices[:,0].mean(), l.vertices[0,1]] for l in vp['cmedians'].get_paths()]
        xy = np.array(xy)
        ax.scatter(xy[:,0], xy[:,1], s=121, c=COLORS[index], marker="x", zorder=3)

        # Set the axis labels
        if plot in [1, 4]:
            ax.set_ylabel('580Y Frequency')
        if index > 3:
            ax.set_xlabel('Month of Year')

# Save the figure to disk
if IMAGEFILE.endswith('tif'):
    fig.savefig(IMAGEFILE, dpi=300, format="tiff", pil_kwargs={"compression": "tiff_lzw"})
else:
    fig.savefig(IMAGEFILE)
