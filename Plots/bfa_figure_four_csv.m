% bfa_figure_four_csv.m
%
% This script gets all of the relevent data to be passed along to another
% programming language for plotting.
clear;

PATH = '../Analysis/Loader/out';

%    1: year
% 2-13: days
DATES = [2025 [6575 6606 6634 6665 6695 6726 6756 6787 6818 6848 6879 6909];
         2030 [8401 8432 8460 8491 8521 8552 8582 8613 8644 8674 8705 8735]; 
         2035 [10227 10258 10286 10317 10347 10378 10408 10439 10470 10500 10531 10561]];

POLICIES = {'bfa-fast-no-asaq' 'Baseline';
            'bfa-aldp10' '10 year AL/DP MFT';
            'bfa-aldp' 'Rapid AL/DP MFT';
            'bfa-tenyear' '10 year Private Market Elimiation';
            'bfa-aldp10-tenyear' '10 year Private Market Elimiation, 10 year AL/DP MFT';
            'bfa-aldp-tenyear' '10 year Private Market Elimiation, Rapid AL/DP MFT';
            'bfa-rapid' 'Rapid Private Market Elimination';
            'bfa-aldp10-rapid' 'Rapid Private Market Elimination, 10 year AL/DP MFT';
            'bfa-aldp-rapid' 'Rapid Private Market Elimination, Rapid AL/DP MFT'};

     
for year = transpose(DATES(:, 1))
    % Clear existing data
    treatmentData = table();
    c580yData = table();
    
    % Get the data for each policy for this year
    dates = DATES(DATES(:, 1) == year, 2:end);
    for policy = 1:size(POLICIES, 1)
        % Note the relevent directory
        directory = fullfile(PATH, char(POLICIES(policy, 1)));
        
        % Get and store the data
        data = get_treatment_data(directory, dates);        
        treatmentData = [treatmentData; table(data, 'RowNames', POLICIES(policy, 2))];
        data = get_580y_data(directory, dates);        
        c580yData = [c580yData; table(data, 'RowNames', POLICIES(policy, 2))];
    end

    % Save the data
    filename = sprintf('yr%d_tmfailures.csv', year);
    writetable(treatmentData, filename, 'WriteVariableNames', false, 'WriteRowNames', true)
    filename = sprintf('yr%d_580y.csv', year);
    writetable(c580yData, filename, 'WriteVariableNames', false, 'WriteRowNames', true)
end

function [data] = get_treatment_data(directory, dates)
    % Get the files and prepare for the data
    files = dir(fullfile(directory, '*treatment-summary*'));
    clinical = zeros(length(files), 1);
    failures = zeros(length(files), 1);

    for ndx = 1:length(files)
        % Load the data
        filename = fullfile(files(ndx).folder, files(ndx).name);
        data = csvread(filename, 1, 0);
        
        % Get the data for the indicated date
        for date = dates
            clinical(ndx) = clinical(ndx) + sum(data(data(:, 2) == date, 5));
            failures(ndx) = failures(ndx) + sum(data(data(:, 2) == date, 6));
        end
    end
    
    % Return the average for the year
    data = transpose(failures ./ clinical);
end

function [data] = get_580y_data(directory, dates)
    % Get the files and prepare for the data
    files = dir(fullfile(directory, '*genotype-summary*'));
    occurrences = zeros(length(files), 1);
    infectedindividuals = zeros(length(files), 1);
    
    for ndx = 1:length(files)
        % Load the data
        filename = fullfile(files(ndx).folder, files(ndx).name);
        raw = csvread(filename, 1, 0);
        
        % Get the data for the indicated date
        for date = dates
            occurrences(ndx) = occurrences(ndx) + sum(raw(raw(:, 2) == date, 7));                 
            infectedindividuals(ndx) = infectedindividuals(ndx) + sum(raw(raw(:, 2) == date, 4));
        end
    end
    
    % Return the frequency data
    data = transpose(occurrences ./ infectedindividuals);
end
