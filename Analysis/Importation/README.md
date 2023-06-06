This directory contains the various scripts that were used for data and analysis and figure generation for the Burkina Faso 580Y importation study.

The following scripts were used to generate plots and data in the manuscript, along with the R scripts in `stats`:

**Data Processing**
- `importLoader.py` - Retrieves the data from the database and saves it as CSV files. Must be run before everything else to ensure the most recent data.

**Manuscript Figures**
- `plot_import_violin.py` - Figure One
- `frequency_stats.m` - Figure Two along with intermediate data files and pairwise comparison plots

**Supplemental Figures**
- `bfa_importation_odds.py` - Generates ASC file used to prepare supplemental figure with the odds of importation to a given cell
- `plot_cellular.py` - Supplemental figures based upon one, two, and three cell models
- `plot_spaghetti.py` - Supplemental figures with twelve month breakdowns
