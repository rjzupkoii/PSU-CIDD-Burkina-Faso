# Organization

The files in this directory are organized as follows:

- `analysis` contains the MATLAB scripts that were used to generate plots used in analysis of results. They were originally in this directory and the paths may not be correct.
- `include` contains MATLAB functions used by the various plots. 

This root directory (i.e., `Plots`) contains the scripts, both MATLAB and Python, that were used to generate the final figures and data points for the manuscript and supplemental materials. The scripts used for supplemental materials contains the code `esm` as part of the filename (e.g., `bfa_esm_clinical_probability.m`). If the scripts are likely to be specific to Burkina Faso they are also prefixed with the ISO Alpha-3 country code (BFA).

# Other Notes

Most of the scripts expect data to be pulled from the database by the loader script in `../Analysis/Loader/` and will look for the data files at `../Analysis/Loader/out/` in the format and structure from that script. The Python scripts (`plot_frequency.py` and `plot_violin.py`) require CSV files generate by `bfa_generate_violin_csv.m` to generate figures. Figures generated should be written to `out` by the scripts.