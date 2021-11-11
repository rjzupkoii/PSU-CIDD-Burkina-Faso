% bfa_fig2_heatmap.m
%
% This script generates the four panel heatmap that appears as Figure 2 of
% the PLOS GPH manuscript. Note that orginally heatmaps were generated for
% each of the study type, but the final manuscirpt was limited to just hte
% one de novo plot.
%
% NOTE that the data used to generate the heatmaps in MATLAB is also being
% exported to CSV for processing in ArcGIS Pro. Converting the CSV files to
% ASC files for import was done by just editing them in Notepad++.
clear;

% Setup our enviornment
addpath('include');
if ~exist('out', 'dir'), mkdir('out'); end

% Settings for the specific study being plotted
FILENAME = '../Analysis/Loader/out/bfa-fast-no-asaq-frequency-map.csv';
STARTDATE = '2007-1-1';
STUDY = 'bfa-fast-no-asaq';

% Get the canonical name of the study and plot it
[name, file] = parse_name(STUDY);
parse_file(FILENAME, name, STARTDATE);


% Generate multiple subplots that contain heatmaps at fixed intervals, note
% that the dates are controled by the loader
function [] = parse_file(filename, name, startdate) 
    raw = readmatrix(filename);
    days = unique(raw(:, 1));

    ndx = 1;
    for day = transpose(days)
        subplot(2, 2, ndx);
        generate(raw, day, startdate);
        ndx = ndx + 1;
    end
        
    sgtitle(sprintf("580Y Frequency %s", name), 'FontSize', 24);
end

% Generate a single heatmap for the given date
function [hm] = generate(raw, date, startDate)
    % Prepare the data structure
    rows = max(raw(:, 3) + 1);
    cols = max(raw(:, 2) + 1);
    map = NaN(rows, cols);

    % Load the data on to the map structure
    data = raw(raw(:, 1) == date, :);
    for values = transpose(data)
        row = values(3) + 1;
        col = values(2) + 1;
        map(row, col) = values(4);    
    end
    
    % Write the data to a CSV file
    writematrix(map, sprintf('map-%d.csv', date));
        
    % Covert the data, prepare the title
    days = addtodate(datenum(startDate), date, 'day');
    title = datestr(datetime(days, 'ConvertFrom', 'datenum'), 'mmmm yyyy');

    % Plot the heatmap and color bar
    hm = heatmap(map, 'MissingDataColor', [235 235 235] / 255);
    hm.Colormap = whitebluered_bfa(max(raw(:, 4)));
	caxis(hm, [min(raw(:, 4)) max(raw(:, 4))]);
    
    % Apply the formatting
    graphic = gca;
    graphic.FontSize = 22;    
    hm.Title = title;
    hm.XDisplayLabels = repmat(' ', cols, 1); 
    hm.YDisplayLabels = repmat(' ', rows, 1);
    grid off;
end

% Derived from the whitebluered function in /include - fix when the red
% coloration starts to be at a frequency of 0.1
function c = whitebluered_bfa(maxval)

    % The number of steps is fixed at 100, so calcluate the stop value
    % where the frequency is 0.1
    stop = 100 - round(0.1 / (maxval / 100), 0);
    
    % Start with white to blue
    r1 = (stop:-1:1)' / stop;
    g1 = r1;
    b1 = ones(stop, 1);
    
    % Next calcluate from blue to red
    stop = 100 - stop;
    r2 = (1:1:stop)' / stop;
    g2 = zeros(stop, 1);
    b2 = (stop:-1:1)' / stop;
    
    % Append the colors and return the final gradient
    c = [[r1; r2] [g1; g2] [b1; b2]];
end
    