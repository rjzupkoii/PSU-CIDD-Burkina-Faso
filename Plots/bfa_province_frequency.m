% bfa_province_frequency.m
%
% Generate a report of the 580Y for the various provinces in Burkina Faso.
addpath('../Analysis/Common');
clear;

scan('../Analysis/Loader/out/', @report);

function [] = report(path, name)
    % Get the list of files and preallocate the data
    files = dir(fullfile(path, '*genotype-summary.csv'));
    values = zeros(45, length(files));
    
    for ndy = 1:length(files)
        % Load the file and discard everything but the last year
        filename = fullfile(files(ndy).folder, files(ndy).name);
        data = csvread(filename, 1, 0);
        data = data(data(:, 2) > 10958, :);
        
        % Calcluate the frequency for each provience
        for ndx = 1:45
            values(ndx, ndy) = sum(data(data(:, 3) == ndx, 7)) / sum(data(data(:, 3) == ndx, 4));
        end
    end
    
    % Find the median and IQR for the proviences
    values = prctile(transpose(values), [25 50 75]);
    [~, ndx] = max(values(2, :));
    province = getLocationName(ndx);
    fprintf('%s: %s = %.3g (IQR: %.3g - %.3g)\n', name, province, values(2, ndx), values(1, ndx), values(3, ndx));
end

function [] = scan(path, report_function)
    files = dir(path);
    data = {}; labels = {};
    for ndx = 1:length(files)
        if ~files(ndx).isdir, continue; end
        if strcmp(files(ndx).name(1), '.'), continue; end
        report_function(fullfile(files(ndx).folder, files(ndx).name), files(ndx).name);
    end
end