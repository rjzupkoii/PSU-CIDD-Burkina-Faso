% study_plots.m
%
% This script is used to generate plots from the study data for Burkina
% Faso.
addpath('../Analysis/Population/include');
clear;

STARTDATE = '2007-1-1';
FILENAME = 'data/genome-test.csv';

raw = csvread(FILENAME, 1, 0);
dn = prepareDates(FILENAME, 1, STARTDATE);

% Calculate the drug resistant cases
data = (raw(:, 3) ./ raw(:, 6)) * 100.0;
peaks = findpeaks(findpeaks(data));

plot(dn, data);

datetick('x', 'yyyy');
ylabel('Percent Clinical Cases with ACT Resistant Genome');
xlabel('Model Year');

