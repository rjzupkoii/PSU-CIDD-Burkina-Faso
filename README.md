# PSU-CIDD-Burkina-Faso

This repository contains configuration, GIS, analysis files used for modeling the prevalence of malaria (*P. falciparum*) in Burkina Faso. These configurations are primarily intended to study 1) the development of antimalarial resistance in the parasite, and 2) possible interventions that the National Malaria Control Programme can implement.

The origin repository for the simulation can be found at [maciekboni/PSU-CIDD-Malaria-Simulation](https://github.com/maciekboni/PSU-CIDD-Malaria-Simulation), although the studies in this repository are intended to be run against 4.0.0 and 4.0.x versions that can be found under [rjzupkoii/PSU-CIDD-Malaria-Simulation](https://github.com/rjzupkoii/PSU-CIDD-Malaria-Simulation).

## Organization

Analysis    - Scripts and data related to analysis subtasks (ex., movement calibration).

GIS         - GIS files for Burkina Faso, as prepared for the simulation.

Plots       - MATLAB and Python scripts used to generate analysis and manuscript plots.

Replicates - Code needed to run the replicates on the ACI cluster.

Studies     - Configuration files used for model validation and *de novo* mutation simulations (business as usual, private market elimination, and multiple-first line therapies).

## Model Execution

All simulations were performed on the Pennsylvania State University’s Institute for Computational and Data Sciences’ Roar supercomputer using the configurations present in [Studies](Studies/) and the replicate queuing scripts present in [Studies/Replicates](Studies/Replicates).