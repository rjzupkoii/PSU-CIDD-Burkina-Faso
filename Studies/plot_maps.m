% plot_maps.m
%
% Generate heatmaps and 580Y frequency plot based upon the data downloaded
% by the Python loader script.
addpath('../Analysis/Population/include');
clear;

STARTDATE = '2007-1-1';
FREQUENCY = '../Analysis/Loader/out/*frequency*.csv';
SUMMARY = '../Analysis/Loader/out/*summary*.csv';

global locationPath;
locationPath = '../Analysis/Population/include/bfa_locations.csv';

%heatmaps(FREQUENCY, STARTDATE);
%plotFrequency(FREQUENCY, STARTDATE);
plotSummary(SUMMARY, STARTDATE);

% Scan the directory to generate summary frequency plots from the data
function [] = plotSummary(directory, startDate)
    files = dir(directory);
    for ndx = 1:length(files)
        filename = fullfile(files(ndx).folder, files(ndx).name);
        rate = char(extractBetween(files(ndx).name, 1, 9));
        rate = strrep(rate, '-', '');
        plotFrequencySummary(filename, rate, startDate);
        plotDistrictFrequencies(filename, rate, startDate);
    end
end

function [] = plotDistrictFrequencies(filename, rate, startDate)
    global locationPath;

    raw = csvread(filename, 1, 0);
    
    % Load the replicates to the subplots
    districts = transpose(unique(raw(:, 3)));    
    for replicate = transpose(unique(raw(:, 1)))
        filtered = raw(raw(:, 1) == replicate, :);
        for district = districts
            subplot(5, 9, district);
            hold on;
            data = filtered(filtered(:, 3) == district, :);
            plot(data(:, 2), data(:, 6));
            hold off;
        end        
    end   
    
    % Covert the xticks to years, these should be the same for all
    xt = {};
    for tick = get(gca, 'XTick')
        xt{end + 1} = datestr(addtodate(datenum(startDate), tick, 'day'), 'yyyy');
    end

    % Label the sub plots
    for district = districts
        subplot(5, 9, district);
        hold on;
        set(gca, 'XTickLabel', xt);
        title(getLocationName(locationPath, district));
        hold off;
    end
        
    % Apply the common labels
    handle = axes(gcf, 'visible', 'off'); 
    handle.XLabel.Visible = 'on';
    handle.YLabel.Visible = 'on';
	handle.FontSize = 18;
    ylabel(handle, '580Y Frequency');
    xlabel(handle, 'Model Year');
    sgtitle(sprintf('580Y Frequency Development with %s Mutation Rate', rate), 'FontSize', 24);
    
    % Save and close
    set(gcf, 'Position', get(0, 'Screensize'));
	saveas(gcf, sprintf('out/%s-frequency-districts.png', rate));
    clf;
    close;  
end

% Generate a single freqeuncy plot that contains all of the replicates in
% the provided file
function [] = plotFrequencySummary(filename, rate, startDate)
    raw = csvread(filename, 1, 0);

    % Load the data, since the model might not be done running, spend a bit
    % extra to generate the correct years
    hold on;
    for replicate = transpose(unique(raw(:, 1)))
        days = []; frequnecy = []; occurances = [];
        
        data = raw(raw(:, 1) == replicate, :);
        for day = transpose(unique(data(:, 2)))
            days(end + 1) = addtodate(datenum(startDate), day, 'day');
            frequnecy(end + 1) = mean(data(data(:, 2) == day, 6));
            occurances(end + 1) = sum(data(data(:, 2) == day, 4));
        end
        yyaxis left;
        plot(days, frequnecy, '-');
        
        yyaxis right;
        plot(days, log10(occurances), '-');
    end
    hold off;

    % Add labels, apply formatting
    datetick('x', 'yyyy');
    xlabel('Model Year');
    
    yyaxis left;
    ylabel('580Y Frequency');
    yyaxis right;
    ylabel('Occurances (log10)');    
        
    replicates = size(unique(raw(:, 1)), 1);
    title({sprintf('580Y Frequency Development with %s Mutation Rate', rate), ...
        sprintf('3%% increase in treatment, %d replicates', replicates)});

    graphic = gca;
    graphic.FontSize = 18;
    
    % Save and close
    set(gcf, 'Position', get(0, 'Screensize'));
    saveas(gcf, sprintf('out/%s-frequency-replicates.png', rate));
    clf;
    close;    
end

% Scan the directory to generate a single frequency plot from the files
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
