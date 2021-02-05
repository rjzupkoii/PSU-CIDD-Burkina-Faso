% treatment_failures.m
%
% Plot the treatment failures from the model.
addpath('../Analysis/Common');
addpath('include');
clear;

DIRECTORY = '../Analysis/Loader/out';
STARTDATE = '2007-1-1';

plot_treatment_failures(DIRECTORY, STARTDATE);

function [] = plot_treatment_failures(directory, startDate)

    % Prepare a color map to use by counting the number of directories
    % NOTE this seems to allocate 2x as many as are needed for some reason
    folders = dir(directory);
    folders(ismember( {folders.name}, {'.', '..'})) = [];

    % Prepare a color map
    colors = colormap(lines(size(folders, 1) / 2));
    ci = 1;    

    % Append the files to the plot
    top = {}; bottom = {};
    files = dir(directory);
    for ndx = 1:length(files)
        % Skip anything that is not the directories we are looking for
        if ~files(ndx).isdir, continue; end
        if strcmp(files(ndx).name(1), '.'), continue; end
                
        % Prepare to append to the plot
        filename = fullfile(files(ndx).folder, files(ndx).name);
        label = strrep(parse_name(files(ndx).name), 'with ', '');
        if startsWith(label, '0.0')
            location = 1;
            top = [top, label];    
        else
            location = 2;
            bottom = [bottom, label];
        end
        
        % Update the plot
        hold on;
        subplot(2, 1, location);
        append_plots(filename, colors(ci, :));
        ci = ci + 1;
    end
        
    % Format the plots
    subplot(2, 1, 1);
    format_legend(top, colors);
    format_plot('Comparison of Muation Rates', startDate);
    
    subplot(2, 1, 2);
    format_legend(bottom, colors);
    format_plot('Comparison of Possible Interventions', startDate);    
end


function [] = append_plots(directory, color)
    files = dir(fullfile(directory, '*treatment*.csv'));
    for ndx = 1:length(files)
        % Load the data, note the unique days
        filename = fullfile(files(ndx).folder, files(ndx).name);
        data = csvread(filename, 1, 0);
        data = data(data(:, 2) > 13 * 365, :);
        
        % Total each day
        days = transpose(unique(data(:, 2)));
        total = zeros(size(days, 1)); index = 1;
        for day = days
            total(index) = sum(data(data(:, 2) == day, 6));
            index = index + 1;
        end
        
        % Append the plot
        plot(days, log10(total), 'Color', color);
    end
end


function [] = format_legend(labels, colors)
    % Add and format the legend
    item = zeros(1, 1);
    index = 1;
    for label = labels
        item(index) = scatter(NaN, NaN, [], colors(index, :), 'filled');
        index = index + 1;
    end
	legend(item, labels, 'Location', 'NorthWest', 'FontSize', 16);
    legend boxoff;
end


function [] = format_plot(plotTitle, startDate)    
    % Format the rest of the plot
    title(plotTitle);
    ylabel('Treatment Failures (log_{10})');    
    xlabel('Model Year');
    axis tight;
    
    % Format the dates based upon the xaxis and ticks, this code might
    % break if the bounds change
    labels = [];
    for tick = xticks()
        tick = addtodate(datenum(startDate), tick, 'day');
        labels = [labels str2num(datestr(tick, 'yyyy'))];
    end
    set(gca, 'XTick', xticks(), 'XTickLabel', labels)
        
    % Set the font sizes
    graphic = gca;
    graphic.FontSize = 24;
end