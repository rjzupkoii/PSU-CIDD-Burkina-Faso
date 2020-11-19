## Movement Analysis
The files contained within this directory were used for analyzing, calibrating, and verifying model movement. The subdirectory `Common` contains data files and Matlab scripts that are used by the Matlab scripts that are present in this directory.

The general workflow for this process is as follows:

1. `parse_marshall.py` was run to generate a mapping between the district ids assigned by the model to the districts used in Marshall et al. (2017)
2. `synthetic_study.m` was run to generate the data points for analysis.
3. `rho_comparison.m` was run to generate the IQR comparison plot.
4. `rho_distance.m` was run to generate synthetic vs. survey data distance plots.
