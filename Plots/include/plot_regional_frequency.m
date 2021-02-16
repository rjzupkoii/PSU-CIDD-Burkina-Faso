% plot_regional_frequency.m
%
% This function generates frequency plots at a regional level based upon 
% the data files in the supplied directory.


% Main entry point for the function, scans the supplied directory for
% subdirectories organized by mutation rate.
function [] = plot_regional_frequency(directory, startdate)
    files = dir(directory);
    for ndx = 1:length(files)
        % Skip anything that is not the directories we are looking for
        if ~files(ndx).isdir, continue; end
        if strcmp(files(ndx).name(1), '.'), continue; end

        % Defer to plot the data sets
        filename = fullfile(files(ndx).folder, files(ndx).name);
        [plotTitle, file] = parse_name(files(ndx).name); 
        generate(filename, startdate, plotTitle, file);
    end
end

% Generates a single plot based upon the data files in the supplyed
% subdirectory, saves the plot to disk.
function [] = generate(directory, startdate, plotTitle, file)

    % Track the ymax so we can set all of the plots
    ymax = 0;

    files = dir(fullfile(directory, '*genotype-summary.csv'));
    for ndx = 1:length(files)
        filename = fullfile(files(ndx).folder, files(ndx).name);
        [regions, max_value] = append_file(filename, startdate);
        ymax = max(ymax, max_value);
    end
        
    % Append plot elements
    for region = 1:regions
        if region == 13, subplot(5, 3, 14);
        else, subplot(5, 3, region); end
        title(getRegionName(region));
        datetick('x', 'yyyy');
        axis tight;
        ylim([0 ymax]);        
    end

    % Apply the common labels
    handle = axes(gcf, 'visible', 'off'); 
    handle.XLabel.Visible = 'on';
    handle.YLabel.Visible = 'on';
    handle.FontSize = 24;
    ylabel(handle, '580Y Frequency');
    xlabel(handle, 'Model Year');
    
    % Apply the title
    sgtitle({sprintf('580Y Frequency %s (%d Replicates)', ...
        plotTitle, length(files))}, 'FontSize', 24);
    
    % Save and close
    set(gcf, 'Position',  [0, 0, 2560, 1440]);
    print('-dtiff', '-r300', sprintf('out/%s-frequency-regions.png', file));
    clf;
    close;      
end

% Parses the supplied data file and adds the data to the plot.
function [regions, ymax] = append_file(filename, startdate)

    % Load the data
    raw = csvread(filename, 1, 0);

    % Start by setting up the district-region mapping
    districts = unique(raw(:, 3));
    mapping = zeros(size(districts, 1), 2);
    for ndx = 1:length(districts)
        mapping(ndx, 1) = ndx;
        [~, mapping(ndx, 2)] = getLocationRegion(ndx);
    end

    % Setup the data sets
    days = unique(raw(:, 2));
    infected_individuals = zeros(size(days, 1), max(mapping(:, 2)));
    weighted_occurances = zeros(size(days, 1), max(mapping(:, 2)));  

    % Extract the data for each day
    day = 1;
    for date = transpose(days)
       data = raw(raw(:, 2) == date, :);
       for row = 1:length(data)
            % Get the region from the district
            region = mapping(mapping(:, 1) == row, 2);

            % Tally up the values for these days
            infected_individuals(day, region) = infected_individuals(day, region) + data(row, 4);
            weighted_occurances(day, region) = weighted_occurances(day, region) + data(row, 7);
       end

       % Move to the next "day"
       day = day + 1;
    end

    % Find the frequency for each provience
    frequency = weighted_occurances ./ infected_individuals;
    
    % Get the dates
    dn = prepareDates(filename, 2, startdate);

	% Note the ymax
    ymax = 0;
    
    % Plot the data for this file
    regions = max(mapping(:, 2));
    for region = 1:regions
        % Keep the subplots balanced
        if region == 13, subplot(5, 3, 14);
        else, subplot(5, 3, region); end
        hold on;
        plot(dn, frequency(:, region));
        hold off;
        
        % Update the ymax
        ymax = max(ymax, max(frequency(:, region)));
    end
end
