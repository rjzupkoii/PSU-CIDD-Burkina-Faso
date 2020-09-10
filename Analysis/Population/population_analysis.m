% population_analysis.m
%
% Plot the basic metrics for the model popuation.
addpath('include');
clear;

FILENAME = 'data/population_data_42.txt';
SCALING = 0.01;

% Load the data, delete the first entry since births/deaths is zero
data = csvread(FILENAME, 1, 0);
data(1, :) = [];

dn = prepareDates(FILENAME, 1, '2007-1-1');
dn(1) = [];

hold on;

yyaxis left;
population = (data(:, 2) ./ SCALING) ./ 1000000;
plot(dn, population);

ylabel('Population (Millions)');

yyaxis right;
births = (data(:, 3) ./ SCALING) ./ 1000;
plot(dn, births);

deaths = (data(:, 4) ./ SCALING) ./ 1000;
plot(dn, deaths);

malariadeaths = (data(:, 5) ./ SCALING) ./ 1000;
plot(dn, malariadeaths);

ylabel('Population (Thousands)');
datetick('x', 'yyyy');
set(gca, 'XLimSpec', 'Tight');

legend({'Total Population', 'Births', 'Deaths', 'Malaria Deaths'}, 'Location', 'NorthWest');
legend boxoff;

graphic = gca;
graphic.FontSize = 18;

hold off;