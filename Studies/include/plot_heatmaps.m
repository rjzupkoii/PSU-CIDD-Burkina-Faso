% plot_heatmaps.m
%
% This function generates heatmaps at the national level based upon the
% frequency files at the supplied path with filter.

% Main entry point for the function, scans the supplied path and filter for
% files to generate heatmaps from. 
function [] = plot_heatmaps(directory, startdate)
    files = dir(directory);
    for ndx = 1:length(files)
        filename = fullfile(files(ndx).folder, files(ndx).name);
        indicies = strfind(files(ndx).name, '-');        
        rate = string(extractBetween(files(ndx).name, 1, indicies(1) - 1));
        parse_file(filename, rate, startdate);
        set(gcf, 'Position', get(0, 'Screensize'));
        saveas(gcf, sprintf('out/%s-heatmap.png', rate));
        clf;
        close;
    end
end

% Generate multiple subplots that contain heatmaps at fixed intervals
function [] = parse_file(filename, rate, startdate) 
    raw = csvread(filename, 1, 0);
    days = unique(raw(:, 1));

    % Since we may run while early, only show plots we have data for
    count = size(days, 1);
    
    % Janurary 2021
    subplot(2, 2, 1);
    if count >= 1, generate(raw, days(1), startdate); end

    % Janurary 2026
    subplot(2, 2, 2);
    if count >= 2, generate(raw, days(2), startdate); end

    % Janurary 2031
    subplot(2, 2, 3);
    if count >= 3, generate(raw, days(3), startdate); end

    % Janurary 2036
    subplot(2, 2, 4);
    if count >= 4, generate(raw, days(4), startdate); end

    sgtitle(sprintf("580Y Frequency with %s Mutation Rate", rate), 'FontSize', 24);
end

% Generate a single heatmap for the given date
function [hm] = generate(raw, date, startDate)
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

    % Plot the heatmap and color bar
    hm = heatmap(map);
    hm.Colormap = colormap(flipud(hot));
	caxis(hm, [min(raw(:, 4)) max(raw(:, 4))]);
    
    % Apply the formatting
    graphic = gca;
    graphic.FontSize = 18;    
    hm.Title = title;
    hm.XDisplayLabels = repmat(' ', cols, 1); 
    hm.YDisplayLabels = repmat(' ', rows, 1);
    grid off;
end