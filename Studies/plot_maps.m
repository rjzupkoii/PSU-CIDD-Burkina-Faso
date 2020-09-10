% plot_maps.m
%
% Generate heatmaps and 580Y frequency plot based upon the data downloaded
% by the Python loader script.
addpath('../Analysis/Population/include');
clear;

STARTDATE = '2007-1-1';
DIRECTORY = '../Analysis/Loader/out/*.csv';

%heatmaps(DIRECTORY, STARTDATE);
plotFrequency(DIRECTORY, STARTDATE);

% Scan the loader directory to generate a single frequency plot from all of
% the files
function [] = plotFrequency(directory, startdate)
    hold on;
    files = dir(directory);
    rates = {};
    for ndx = 1:length(files)
        filename = fullfile(files(ndx).folder, files(ndx).name);
        rate = char(extractBetween(files(ndx).name, 1, 5));
        rates{end + 1} = strrep(rate, '-', '');
        generateFrequency(filename, rates{end}, startdate);
    end
    hold off;
    
    % Add labels, apply formatting
    title('Burkina Faso, increase in 580Y frequency over time');
    ylabel('580Y frequency (average of all cells)');
    datetick('x', 'yyyy');
    set(gca, 'XLimSpec', 'Tight');
    
    % Format the legend
    hleg = legend(cellstr(rates), 'Location', 'NorthWest', 'NumColumns', 2);
    title(hleg, 'Increase in Treatment Coverage');
    legend boxoff;

    graphic = gca;
    graphic.FontSize = 18;
    
    % Save and close
    set(gcf, 'Position', get(0, 'Screensize'));
    saveas(gcf, 'out/frequencies.png');
    clf;
    close;
end

% Add a single frequency plot to the current GCF
function [] = generateFrequency(filename, rate, startdate)
    raw = csvread(filename, 1, 0);
    days = unique(raw(:, 1));
    values = [];
    for day = transpose(days)
        data = raw(raw(:, 1) == day, :);
        values(end + 1) = sum(data(:, 4)) / size(data, 1);
    end
    dn = prepareDates(filename, 1, startdate);
    plot(dn, values);
   
    % Uncommon to show rate label
    %text(max(dn), max(values), rate)
end

% Scan the loader directory to generate heatmaps for all of the files
function [] = heatmaps(directory, startdate)
    files = dir(directory);
    for ndx = 1:length(files)
        filename = fullfile(files(ndx).folder, files(ndx).name);
        rate = char(extractBetween(files(ndx).name, 1, 5));
        rate = strrep(rate, '-', '');    
        plotHeatmaps(filename, rate, startdate);
        set(gcf, 'Position', get(0, 'Screensize'));
        saveas(gcf, sprintf('out/%s-heatmap.png', rate));
        clf;
    end
    close;
end

% Generate multiple subplots that contain heatmaps at fixed intervals
function [] = plotHeatmaps(filename, rate, startdate) 
    raw = csvread(filename, 1, 0);
    days = unique(raw(:, 1));

    subplot(2, 2, 1);
    generateHeatmap(raw, days(24), startdate);

    subplot(2, 2, 2);
    generateHeatmap(raw, days(84), startdate);

    subplot(2, 2, 3);
    generateHeatmap(raw, days(144), startdate);

    subplot(2, 2, 4);
    if size(days, 1) < 204
        generateHeatmap(raw, days(end), startdate);
    else
        generateHeatmap(raw, days(204), startdate);
    end

    sgtitle(["Burkina Faso, 580Y frequency", sprintf("%s%% increase in coverage", rate)]);
end

% Generate a single heatmap for the given date
function [hm] = generateHeatmap(raw, date, startDate)
    % Prepare the data structure
    rows = max(raw(:, 3) + 1);
    cols = max(raw(:, 2) + 1);
    map = zeros(rows, cols);

    % Load the data on to the map structure
    data = raw(raw(:, 1) == date, :);
    for values = transpose(data)
        row = values(3) + 1;
        col = values(2) + 1;
        map(row, col) = values(4);    
    end
    
    % Covert the data, prepare the title
    days = addtodate(datenum(startDate), date, 'day');
    title = datestr(datetime(days, 'ConvertFrom', 'datenum'), 'mmmm yyyy');

    % Apply the formatting
    hm = heatmap(map);
    hm.Title = title;
    hm.XDisplayLabels = repmat(' ', cols, 1); 
    hm.YDisplayLabels = repmat(' ', rows, 1);
    hm.Colormap = colormap(flipud(hot));
    grid off;
end
