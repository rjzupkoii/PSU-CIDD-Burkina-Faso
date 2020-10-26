% generate_bfa_plots.m
%
% Generate heatmaps and 580Y frequency plot based upon the data downloaded
% by the Python loader script.
addpath('include');
addpath('../Analysis/Common');
clear;

STARTDATE = '2007-1-1';
DIRECTORY = '../Analysis/Loader/out';
FREQUENCY = '../Analysis/Loader/out/*frequency*.csv';

if ~exist('out', 'dir'), mkdir('out'); end

% NOTE for most of these the default image size is 2560 x 1440 at 300 DPI
%      exact sizes can be changed though

plot_heatmaps(FREQUENCY, STARTDATE);
plot_pfpr_heatmap('data/0.001983-bfa-pfpr2_10-average.csv', STARTDATE);

plot_district_frequency(DIRECTORY, STARTDATE);
plot_regional_frequency(DIRECTORY, STARTDATE);
plot_national_frequency(DIRECTORY, STARTDATE);
