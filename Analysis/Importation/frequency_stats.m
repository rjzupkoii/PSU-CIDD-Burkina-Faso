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

% Generate the p-value plots
% for imports = 3:3:9
%     for symptomatic = 0:1
%         wilcoxon(imports, symptomatic);
%     end
% end

generate_probablity_plot();

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

            % Convert frequencies below 10^-5 to zero since these are
            % likely a model artifact
            block(block < -5) = -Inf;
    
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
    save_figure(sprintf('out/boxplot-%d-symptomatic-%d.png', imports, symptomatic));
end

function [] = generate_probablity_plot()
    labels = {};
    hold on;
    for imports = 3:3:9
        for symptomatic = 0
    
            % Load the data
            filename = sprintf('intermediate/final-frequency-%d-symptomatic-%d.csv', imports, symptomatic);
            data = readmatrix(filename);
    
            % Calculate the probablities
            probabilities = zeros(1, 12);
            for month = 1:12
                established = sum(data(:, month) > -3.5);
                replicates = sum(~isnan(data(:, month)));
                probabilities(month) = (established / replicates) * 100.0;
            end
    
            % Add to the plot
            scatter(1:12, probabilities, 'filled');
            labels{end + 1} = sprintf('Importations: %d/mo, Symptomatic: %s', imports, yesno(symptomatic));
        end
    end
    
    % Note the bounds of the rainy season
    xl = xline(6, '-.', 'Start Rainy Season');
    xl.LabelVerticalAlignment = 'middle';
    xl = xline(10, '-.', 'End Rainy Season');
    xl.LabelVerticalAlignment = 'middle';
    
    % Add the legend
    legend(labels);
    legend boxoff;
    
    % Format the plot
    title('Probablity of Establishment');
    ylabel('Establishment Probablity');
    xlabel('');
    xlim([1 12]);
    xticks(1:12);
    xticklabels(months);
    graphic = gca;
    graphic.FontSize = 18;

    % Save the image to disk
    save_figure('out/probablity_plot.png');
end

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

    % Save the image to disk
    save_figure(sprintf('out/wilcoxon-%d-symptomatic-%d.png', imports, symptomatic));
end
