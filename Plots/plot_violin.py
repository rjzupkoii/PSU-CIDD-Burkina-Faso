#!/usr/bin/env python3

# plot_violin.py
#
# Clean the temp from the loader and plot is as violin plots.
import csv
import glob
import matplotlib.pyplot as plt 
import numpy as np 
import os
import pandas as pd

from matplotlib import rc_file
from pathlib import Path


def plot(filter, yaxis, filename):
    # Set our formatting
    rc_file("matplotlibrc-custom")

    # Read the first CSV file and prepare the temp
    path_root = Path('data')
    temp = pd.read_csv(Path(path_root, filter.format(2025)), index_col=0, header=None).T
    replicates = temp.shape[0]
    studies = temp.shape[1]
    
    # Read the rest of the CSV files
    years = ['2025', '2030', '2035']
    data = np.zeros((len(years), replicates, studies))
    for i, yr in enumerate(years):
        data[i,:,:] = pd.read_csv(Path(path_root, filter.format(yr)), index_col=0, header=None).T
    
    # Violin plot, grouped by policy
    data_labels = temp.columns
    data_labels = ['Baseline', 
        '10 year AL/DP MFT', 
        'Rapid AL/DP MFT',
        '10 year Private Market Elimination',
        '10 year Private Market Elimination,\n10 year AL/DP MFT',
        '10 year Private Market Elimination,\nRapid AL/DP MFT',
        'Rapid Private Market Elimination',
        'Rapid Private Market Elimination,\n10 year AL/DP MFT',
        'Rapid Private Market Elimination,\nRapid AL/DP MFT']
    fig, axs = plt.subplots(nrows=3, ncols=3, figsize=(20, 25), sharey=True, sharex=True,
                            gridspec_kw={'left':0.09, 'right':0.97, 'top':0.95, 'bottom':0.06, 'wspace':0.2, 'hspace':0.22})
    
    # Format the sub plots
    for ax, (il, l) in zip(axs.flat, enumerate(data_labels)):
        ax.violinplot(data[:,:,il].T, positions=range(len(years)))
        ax.set_xticks(range(len(years)))
        ax.set_xticklabels(years)
        if il % 3 == 0:
            ax.set_ylabel(yaxis)
        if il // 3 == 2:
            ax.set_xlabel('Model year')
        ax.set_title(l, fontsize=20)

    # Save the figure to disk
    fig.savefig(filename)


# Convert the temp from the loader to the expected format
def clean():
    PATH = "../Analysis/Loader/out/annual-data"
    POLICIES = ['bfa-fast-no-asaq',
                'bfa-aldp10',
                'bfa-aldp',
                'bfa-tenyear',
                'bfa-aldp10-tenyear',
                'bfa-aldp-tenyear',
                'bfa-rapid',
                'bfa-aldp10-rapid',
                'bfa-aldp-rapid']

    for year in (2025, 2030, 2035):
        for current in POLICIES:        
            for file in glob.glob("{}/{}-*.csv".format(PATH, year)):
                temp = pd.read_csv(file)
                for column in temp.filename.unique():
                    
                    # Only write the current column to preserve order
                    if column == current:

                        # Filter the temp and write it
                        clinical = temp[temp.filename == column].clinicalper1000.to_numpy()
                        pfpr = temp[temp.filename == column].pfpr2to10.to_numpy()
                        write_row("data/yr{}_clinical.csv".format(year), [column] + list(clinical))
                        write_row("data/yr{}_pfpr.csv".format(year), [column] + list(pfpr))


def write_row(filename, temp):
    with open(filename, "a") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(temp)


if __name__ == "__main__":
    if not os.path.isfile("data/yr2025_clinical.csv"):
        clean()
    plot("yr{}_pfpr.csv", "$\it{Pf}$PR$_{2-10}$", "out/bfa-2025to2035-pfpr.png")
    plot("yr{}_clinical.csv", "Clinical Cases per 1000", "out/bfa-2025to2035-clinical.png")
    plot("yr{}_tmfailures.csv", "Treatment Failure Rate", "out/bfa-2025to2035-treatmentfailures.png")
    plot("yr{}_580y.csv", "580Y Frequency", "out/bfa-2025to2035-580y.png")
    plot("yr{}_plasmespin.csv", "Frequency of \nmulticopy $\it{Plasmepsin}$ 2,3", "out/bfa-2025to2035-plasmepsin.png")