% basic_plots.m
%
% This file contains various basic plots that were used while writing the
% manuscript but that may not appear in the manuscript or supplmental
% materials.
addpath('../Analysis/Common');
clear;

FILENAME = 'data/0.001983-summary-pfpr.csv';
STARTDATE = '2007-1-1';

plot_october_pfpr(FILENAME, STARTDATE);

% Plot the data set that is limited October (approximate peak of Burkina
% Faso malaria season).
function [] = plot_october_pfpr(filename, startdate)
    data = csvread(filename, 1, 0);
    dn = prepareDates(filename, 1, startdate);
    plot(dn, data(:, 2));

    datetick('x', 'yyyy');

    title('Burkina Faso - October PfPR_{2 to 10}, 0.001983 mutation rate');
    ylabel('PfPR_{2 to 10}');
    xlabel('Model Year');

    graphic = gca;
    graphic.FontSize = 18;
end