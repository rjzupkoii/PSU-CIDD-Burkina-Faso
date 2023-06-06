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
process('data/bfa-merged.csv', filter, false);
process_year('data/bfa-merged.csv', filter);

% Generate the plots for the manuscript
mkdir('out');
generate_pairwise_plots();
mkdir('plots/manuscript');
generate_probablity_plot(-3, 'binomial');

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
    for imports = [1, 3, 6, 9]
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
    for imports = [1, 3, 6, 9]
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
    for imports = [1, 3, 6, 9]
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

function [] = generate_probablity_plot(threshold, distribution)
    % Prepare for the figure
    fig = figure;
    ndx = 0;
    ymax = 0;
    titles = cell(6);
    pr_all = []; pr_low = []; pr_high = [];

    for symptomatic = 0:1
        for imports = [1 3 6 9]
            % Load the data
            filename = sprintf('intermediate/final-frequency-%d-symptomatic-%d.csv', imports, symptomatic);
            data = readmatrix(filename);
    
            % Calculate the probablities
            probabilities = zeros(1, 12);
            err_low = zeros(1, 12);
            err_high = zeros(1, 12);
            for month = 1:12
                % Total establishments and replicate count
                established = sum(data(:, month) > threshold);
                replicates = size(data(:, month), 1);

                if strcmp(distribution, 'normal')
                    % Normal distribution and 95% CI
                    probabilities(month) = established / replicates;
                    err_high(month) = 1.96 * sqrt(abs((probabilities(month) * (1 - probabilities(month))) / replicates));
                elseif strcmp(distribution, 'binomial')
                    % Binomial 
                    [phat, pci] = binofit(established, replicates);
                    probabilities(month) = phat;
                    err_low(month) = pci(1);
                    err_high(month) = pci(2);
                else
                    error('Unknown distrubtion!')
                end

                % Probablity aross all posiblities
                pr_all(end + 1) = probabilities(month);         %#ok
                if month >= 6 && month <= 10
                    pr_high(end + 1) = probabilities(month);    %#ok
                else
                    pr_low(end + 1) = probabilities(month);     %#ok
                end
            end
    
            % Note the ymax
            if ymax < max(probabilities + err_high)
                ymax = max(probabilities + err_high);
            end

            % Move to the next subplot
            ndx = ndx + 1;
            subplot(2, 4, ndx);            
                
            % Add to the plot
            hold on;
            titles{ndx} = sprintf('Importations: %d/mo, Symptomatic: %s', imports, yesno(symptomatic));
            scatter(1:12, probabilities, 125, [100 100 100] / 255, 'filled');
            if strcmp(distribution, 'normal')
                bar = errorbar(1:12, probabilities, err_high, 'LineStyle','none', 'Color', 'black');
            elseif strcmp(distribution, 'binomial')
                bar = errorbar(1:12, probabilities, err_low, err_high, 'LineStyle','none', 'Color', 'black');
            end
            bar.LineWidth = 0.85;
            bar.Color =  [100 100 100] / 255;
        end
    end

    for ndx = 1:8
        subplot(2, 4, ndx);
        ylim([0 ymax]);
        format(titles{ndx}, ymax);
    end

    % Format the plot
    han = axes(fig, 'visible','off'); 
    han.YLabel.Visible = 'on';
    ylabel(han, {sprintf('Probablity of Achiving Frequency 10^{%0.f} After Ten Years', threshold), ''}, 'FontSize', 18);

    % Report median and IQR
    fprintf('Threshold %.2f / %s\n', threshold, distribution);
    fprintf('All (n = %d), median: %.2f (IQR %.2f - %.2f)\n', size(pr_all, 2), prctile(pr_all, [50 25 75]));
    fprintf('Low (n = %d), median: %.2f (IQR %.2f - %.2f)\n', size(pr_low, 2), prctile(pr_low, [50 25 75]));
    fprintf('High (n = %d), median: %.2f (IQR %.2f - %.2f)\n\n', size(pr_high, 2), prctile(pr_high, [50 25 75]));

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
    graphic = gca;
    graphic.FontSize = 16;
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
