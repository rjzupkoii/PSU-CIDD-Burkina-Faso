% percent_increase.m
%
% Script to parse out the percent increase for each replicate and produce a 
% simple heatmap of the data.

% Table Layout
% 1 - replicate id
% 2 - month; 3 - imports; 4 - symptomatic; 5 - mutations 
% 6 - dayselapsed
% 7 - infectedindividuals; 8 - clinicalepisodes
% 9 - clinicaloccurrences; 10 - weightedoccurrences

clear;

files = dir(fullfile('../data', 'bfa-importation-*.csv'));
for ndx = 1:length(files)
    filename = sprintf('../data/%s', files(ndx).name);
    process_study(filename);
end

function [] = process_study(filename)
    % Read the data from the file and return if there are mutations
    raw = readmatrix(filename);
    if raw(1, 5) == 1
        return;
    end
    
    % Parse out the relevent information
    month = raw(1, 2); imports = raw(1, 3); symptomatic = raw(1, 4);
    
    % Get the unqiue dates and use these as the header for the output
    dates = unique(raw(:, 6));
    dates = transpose(dates(1:end - 1));
    output = zeros(51, size(dates, 2));
    output(1, :) = dates;
    
    ndx = 2;
    for replicate = transpose(unique(raw(:, 1)))
        % Filter the raw data to the replicate and calcluate the frequency
        data = raw(raw(:, 1) == replicate, :);
        frequency = data(:, 10) ./ data(:, 7);
        
        % Calcluate the percent increase and assign it to the next empty row
        output(ndx, :) = transpose(diff(frequency) ./ frequency(1:end - 1) * 100);
        ndx = ndx + 1;
    end
    
    % Save the raw data to a CSV
    filename = sprintf('out/%d-%d-%d.csv', month, imports, symptomatic);
    writematrix(output, filename);
    
    % Produce a heatmap with the data
    hm = heatmap(output(2:end, :));
    hm.Title = sprintf('Month: %d; Imports: %d; Symptomatic: %d', month, imports, symptomatic);
    hm.XLabel = 'Days Elapsed';
    hm.YLabel = 'Replicate Number';
    hm.XDisplayLabels = dates;
    
    % Format the figure 
    graphic = gca;
    graphic.FontSize = 16;
    set(gcf, 'Position',  [0, 0, 2560, 1440]);
    
    % Save the heatmap 
    filename = sprintf('out/%d-%d-%d.png', month, imports, symptomatic);
    print('-dpng', '-r300', filename);
    clf;
    close;
end
