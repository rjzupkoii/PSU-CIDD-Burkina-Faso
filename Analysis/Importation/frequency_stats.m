% frequency_stats.m
% 
% Parse the data from the simuation and calcluate the statistical power of
% the observations.
warning('off', 'MATLAB:MKDIR:DirectoryExists');
addpath('include');
clear;

% Filter to use when preparing data, NaN disables filtering
filter = NaN;

% Process the data sets
mkdir('intermediate');
% process('data/bfa-merged.csv', filter, false);
process_year('data/bfa-merged.csv', filter);

% % Generate the plots for the manuscript
% generate_pairwise_plots();
generate_probablity_plot(-3.5);
generate_probablity_plot(-3);

function [] = process_year(filename, filter)
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
            yearly = filtered(filtered.month == 0, :);
            frequency = yearly.frequency;
            frequency(length(frequency) + 1:50) = NaN;

            % Filter out frequencies below the given value, if given
            if ~isnan(filter)
                frequency(frequency < filter) = -Inf;
            end
    
            % Save the data for the figure to disk
            file = sprintf('intermediate/year-frequency-%d-symptomatic-%d.csv', imports, symptomatic);
            writematrix(frequency, file);
        end
    end
end

function [] = process(filename, filter, plot)
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

            % Filter out frequencies below the given value, if given
            if ~isnan(filter)
                block(block < filter) = -Inf;
            end
    
            % Save the data for the figure to disk
            file = sprintf('intermediate/final-frequency-%d-symptomatic-%d.csv', imports, symptomatic);
            writematrix(block, file);
    
            if plot; generate_plot(block, imports, symptomatic); end
        end
    end
end

function [] = generate_pairwise_plots()
    for imports = 3:3:9
        for symptomatic = 0:1
            wilcoxon(imports, symptomatic);
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

function [] = generate_probablity_plot(threshold)
    % Prepare for the figure
    fig = figure;
    ndx = 0;
    ymax = 0;
    titles = cell(6);

    for symptomatic = 0:1
        for imports = 3:3:9
            % Load the data
            filename = sprintf('intermediate/final-frequency-%d-symptomatic-%d.csv', imports, symptomatic);
            data = readmatrix(filename);
    
            % Calculate the probablities
            probabilities = zeros(1, 12);
            errors = zeros(1, 12);
            for month = 1:12
                established = sum(data(:, month) > threshold);
                replicates = sum(~isnan(data(:, month)));
                probabilities(month) = (established / replicates) * 100.0;
                errors(month) = 1.96 * sqrt(abs((probabilities(month) * (1 - probabilities(month))) / replicates));
            end
    
            % Note the ymax
            if ymax < max(probabilities + errors)
                ymax = max(probabilities + errors);
            end

            % Move to the next subplot
            ndx = ndx + 1;
            subplot(2, 3, ndx);            
                
            % Add to the plot
            hold on;
            titles{ndx} = sprintf('Importations: %d/mo, Symptomatic: %s', imports, yesno(symptomatic));
            scatter(1:12, probabilities, 15, [100 100 100] / 255, 'filled');
            errorbar(1:12, probabilities, errors, 'LineStyle','none', 'Color', 'black');
        end
    end

    for ndx = 1:6
        subplot(2, 3, ndx);
        ylim([0 ymax]);
        format(titles{ndx}, ymax);
    end

    % Format the plot
    sgtitle(sprintf('Probablity of Establishment (threshold > %0.1f)', threshold), 'FontSize', 18);
    han = axes(fig, 'visible','off'); 
    han.YLabel.Visible = 'on';
    ylabel(han, {'Establishment Probablity', ''}, 'FontSize', 18);

    % Save the image to disk
    save_figure(sprintf('plots/manuscript/probablity%0.1f-threshold.png', threshold), true);
    save_figure(sprintf('plots/manuscript/probablity%0.1f-threshold.svg', threshold));
end

function [] = format(plot_title, ymax)
    % Note the bounds of the rainy season
    xline(6, '-.', 'Start Rainy Season');
    xline(10, '-.', 'End Rainy Season');

    fill = area([6 10], [ymax ymax]);
    fill(1).FaceColor = [0.8 0.8 0.8];
    fill(1).EdgeColor = [1 1 1];
    fill(1).FaceAlpha = 0.2;
    children = get(gca, 'Children');
    set(gca, 'Children', flipud(children));

    % Append the title
    title(plot_title, 'FontWeight', 'normal', 'FontSize', 16);

    % Generic formatting
    xlim([0 13]);
    xticks(1:12);
    xticklabels(months);
    ytickformat('percentage');
    graphic = gca;
    graphic.FontSize = 14;
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
