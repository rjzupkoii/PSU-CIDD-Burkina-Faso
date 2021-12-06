% frequency_stats.m
% 
% Parse the data from the simuation and calcluate the statistical power of
% the observations.
warning('off', 'MATLAB:MKDIR:DirectoryExists');
addpath('include');
clear;

% Process the data sets
mkdir('intermediate');
process('data/bfa-merged.csv', false);

% TODO Clip results < -4 since the importation proximy to end of model can
% skew the results. Repeat for -3.5 and -3 for MS

% Perform some stats
%wilcoxon(3, 0);


filename = sprintf('intermediate/final-frequency-%d-symptomatic-%d.csv', 3, 0);
data = readmatrix(filename);
[p, tbl, stats] = kruskalwallis(data, [], 'off');
multcompare(stats);


function [] = wilcoxon(imports, symptomatic)
    % Read the data
    filename = sprintf('intermediate/final-frequency-%d-symptomatic-%d.csv', imports, symptomatic);
    data = readmatrix(filename);
    
    % Generate the p-values
    p = nan(12, 12);
    for ndx = 1:12
        for ndy = ndx:12
            p(ndx, ndy) = ranksum(data(:, ndx), data(:, ndy));
        end
    end

    % Generate the plot
    map = heatmap(p);
    map.Title = sprintf('Wilcoxon rank sum (Importations: %d/mo, Symptomatic: %s)', imports, yesno(symptomatic));
    map.XDisplayLabels = months;
    map.YDisplayLabels = months;
    map.MissingDataColor = [200 200 200] / 255;
end

function [] = process(filename, plot)
    % Load the data and drop de novo studies
    data = readtable(filename, 'PreserveVariableNames', true);
    data = data(data.mutations == 0, :);
    
    % Restrict the data to the last recorded date
    dates = unique(data.dayselapsed);
    data = data(data.dayselapsed == max(dates), :);
    
    % Calcluate the frequency and store as log10
    data.frequency = log10(data.weightedoccurrences ./ data.infectedindividuals);
    
    % Generate the counts
    for imports = 3:3:9
        for symptomatic = 0:1
            % First pass filtering
            filtered = data(data.imports == imports, :);
            filtered = filtered(filtered.symptomatic == symptomatic, :);
            
            % Filter to the month prepare the block data
            block = zeros(50, 12);
            for month = 1:12
                monthly = filtered(filtered.month == month, :);
                frequency = monthly.frequency;
                frequency(length(frequency) + 1:50) = NaN;
                block(:, month) = frequency;
            end
%            block(block == -Inf) = -9;        % TODO Determine if this is valid
    
            % Save the data for the figure to disk
            file = sprintf('intermediate/final-frequency-%d-symptomatic-%d.csv', imports, symptomatic);
            writematrix(block, file);
    
            if plot; generate_plot(block, imports, symptomatic); end
        end
    end
end

function [] = generate_plot(block, imports, symptomatic)
    % Prepare the boxplot
    boxplot(block, months);
    sgtitle(sprintf('Importations: %d/mo, Symptomatic: %s', imports, yesno(symptomatic)), 'FontSize', 18);
    ylabel('580Y Frequency (log_{10})');
    graphic = gca;
    graphic.FontSize = 18;
    
    % Save the image to disk
    set(gcf, 'Position',  [0, 0, 2560, 1440]);
    image = sprintf('out/boxplot-%d-symptomatic-%d.png', imports, symptomatic);
    print('-dtiff', '-r300', image);
    clf;
    close;
end
