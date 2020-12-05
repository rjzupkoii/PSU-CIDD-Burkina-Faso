% iqr_calculation.m
% 
% Scan the directory of the loader output and report the IQR for the
% replicates of each directory. 
addpath('include');
clear;

[data, labels] = scan('../Analysis/Loader/out/');
create_boxplot(data, labels);

% Scan the directory for relevent subdirectories
function [data, labels] = scan(path)
    files = dir(path);
    
    data = {}; labels = {};
    for ndx = 1:length(files)
        if ~files(ndx).isdir, continue; end
        if strcmp(files(ndx).name(1), '.'), continue; end
        values = report(fullfile(files(ndx).folder, files(ndx).name), files(ndx).name);
        [~, ~, label] = parse_name(files(ndx).name);
        labels{end + 1} = label;
        data{end + 1} = values;
    end
end

% Generate the IRQ output and return the last maximum value for the last
% year of each replicate in the given path
function [values] = report(path, name)
    values = [];
        
    files = dir(fullfile(path, '*.csv'));
    for ndx = 1:length(files)
        % Load the data and discard everything but the last year
        filename = fullfile(files(ndx).folder, files(ndx).name);
        data = csvread(filename, 1, 0);
        data = data(data(:, 2) > 10958, :);

        % Find the max value for the year
        values = [values max(sum(data(:, 7)) / sum(data(:, 4)))];
    end

    % Find 25th, 50th, and 75th percentile of the data
    result = prctile(values, [25 50 75]);
    
	% Pretty print the results
    if strcmp(name, 'bfa-import')
        fprintf("%s: %.2e (IQR: %.2e - %.2e), max: %e.2, count: %d\n", name, result(2), result(1), result(3), max(values), size(values, 2));
        return
    end
    fprintf("%s: %.2g (IQR %.2g - %.2g), max: %.2g, count: %d\n", name, result(2), result(1), result(3), max(values), size(values, 2));
end

function [] = create_boxplot(data, labels)
    % Seperate the biological data from policy data
    bio = {};
    bio{end + 1} = cell2mat(data(1));
    bio{end + 1} = cell2mat(data(2));
    bio{end + 1} = cell2mat(data(6));
    add_plot(bio, 1, {labels{1:2} labels{6}}, "Biological Scenarios");

    % Remove the biological data from policy data
    data(6) = [];
    data(2) = [];
    data(1) = [];
    add_plot(data, 2, {labels{3:5} labels{7:end}}, "Policy Interventions");    
end

% Add a boxplot to the plot already in progress at the given index with the
% given labels
function [] = add_plot(data, index, labels, plot_title)
    % Create the plot
    subplot(1, 2, index);
    indicies = num2cell(1:numel(data));
    temp = cellfun(@(x, y) [x(:) y*ones(size(x(:)))], data, indicies, 'UniformOutput', 0);
    temp = vertcat(temp{:});
    boxplot(temp(:,1), temp(:, 2), 'Labels', labels);
        
    % Format the plot
    title(plot_title);
    ylabel('580Y Frequency');
	graphic = gca;
    graphic.FontSize = 24;   
    set(gca, 'FontSize', 18, 'XTickLabelRotation', 15)   
end
