% analysis.m
%
% This script is intended to look at the data generated for a single cell to 
% determine why 580Y shows cyclic behavior under some scenarios.
addpath('../../Analysis/Population/include');
clear;

hold on;

update_plot('data/10k-001983-0.1-bfa.csv');
update_plot('data/10k-001983-0.1-bfa-tf.csv');
update_plot('data/10k-001983-0.5-bfa.csv');
update_plot('data/10k-001983-0.5-bfa-tf.csv');
update_plot('data/10k-001983-1.0-bfa.csv');
update_plot('data/10k-001983-1.0-bfa-tf.csv');

update_plot('data/100k-001983-0.1-bfa.csv');
update_plot('data/100k-001983-0.1-bfa-tf.csv');
update_plot('data/100k-001983-0.5-bfa.csv');
update_plot('data/100k-001983-0.5-bfa-tf.csv');
update_plot('data/100k-001983-1.0-bfa.csv');
update_plot('data/100k-001983-1.0-bfa-tf.csv');

plot_seasonality('data/10k-001983-0.1-bfa.csv');
hold off;

datetick('x', 'yyyy');
xlabel('Model Year');

yyaxis right;
ylabel('Beta Multiplier');

function [] = update_plot(filename)
    data = csvread(filename, 1, 0);
    dn = prepareDates(filename, 1, '2007-01-01');
    plot(dn, data(:, 6));   
end

function [] = plot_seasonality(filename)
    base = 0.1; a = -0.9; b = 2.5; phi = 146;
    
    % Get the days from the data set
    data = csvread(filename, 1, 0);
    days = unique(data(:, 1));
    
    % Use the days to determine what the multiplier was at that point in
    % time, note we rectify th sine wave after all dates are processed
    multiplier = zeros(size(days, 1), 1);
    for ndx = 1:size(days, 1)
        days(ndx) = addtodate(datenum('2007-01-01'), days(ndx), 'day');
        dayofyear = day(datetime(days(ndx), 'ConvertFrom', 'datenum'), 'dayofyear');
        multiplier(ndx) = a * sin(b * pi() * (phi - dayofyear) / 365);
    end

    % Rectify the sine wave and add the base
    multiplier(multiplier < 0) = 0;
    multiplier = multiplier + base;

    % Plot the pattern
    yyaxis right;
    plot(days, multiplier)
end

function [] = plot_weighted(filename)
    raw = csvread(filename, 1, 0);
    days = unique(raw(:, 2));

    weighted = zeros(size(days, 1), 1);
    unweighted = zeros(size(days, 1), 1);
    
    for ndx = 1:length(days)
       day = days(ndx);
       data = raw(raw(:, 2) == day, :);

       popuation = sum(data(:, 3));
       weight = data(:, 3) ./ popuation;
       weighted(ndx) = sum(data(:, 5) .* weight) / sum(data(:, 4) .* weight);

       unweighted(ndx) = sum(data(:, 5)) / sum(data(:, 4));
    end
    
    dn = prepareDates(filename, 2, '2007-01-01');
    plot(dn, unweighted, 'LineWidth', 2);
%    plot(dn, weighted, 'LineWidth', 2);
end