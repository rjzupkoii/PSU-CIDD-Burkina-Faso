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
            'bfa-tenyear' '10 year Private Market Elimination';
            'bfa-aldp10-tenyear' '10 year Private Market Elimination, 10 year AL/DP MFT';
            'bfa-aldp-tenyear' '10 year Private Market Elimination, Rapid AL/DP MFT';
            'bfa-rapid' 'Rapid Private Market Elimination';
            'bfa-aldp10-rapid' 'Rapid Private Market Elimination, 10 year AL/DP MFT';
            'bfa-aldp-rapid' 'Rapid Private Market Elimination, Rapid AL/DP MFT'};

     
for year = transpose(DATES(:, 1))
    % Clear existing data
    treatmentData = table();
    c580yData = table();
    plasmepsinData = table();
    knfData = table();
    knfPlasmepsinData = table();
            
    % Get the data for each policy for this year
    dates = DATES(DATES(:, 1) == year, 2:end);
    for policy = 1:size(POLICIES, 1)
        % Note the relevent directory
        directory = fullfile(PATH, char(POLICIES(policy, 1)));
        
        % Treatment failures
        data = get_treatment_data(directory, dates);        
        treatmentData = [treatmentData; table(data, 'RowNames', POLICIES(policy, 2))];

        % 580Y frequency
        data = get_frequency_data(directory, '.....Y.', dates);
        c580yData = [c580yData; table(data, 'RowNames', POLICIES(policy, 2))];

        % Plasmepsin 2/3 double copy frequency
        data = get_frequency_data(directory, '......2', dates);
        plasmepsinData = [plasmepsinData; table(data, 'RowNames', POLICIES(policy, 2))];
        
        % KNF frequency
        data = get_frequency_data(directory, 'KNF....', dates);
        knfData = [knfData; table(data, 'RowNames', POLICIES(policy, 2))];
        
        % KNF plus Plasmepsin 2/3 double copy frequency
        data = get_frequency_data(directory, 'KNF...2', dates);
        knfPlasmepsinData = [knfPlasmepsinData; table(data, 'RowNames', POLICIES(policy, 2))];     
    end

    % Save the data
    filename = sprintf('yr%d_tmfailures.csv', year);
    writetable(treatmentData, filename, 'WriteVariableNames', false, 'WriteRowNames', true);
    filename = sprintf('yr%d_580y.csv', year);
    writetable(c580yData, filename, 'WriteVariableNames', false, 'WriteRowNames', true);    
    filename = sprintf('yr%d_plasmespin.csv', year);
    writetable(plasmepsinData, filename, 'WriteVariableNames', false, 'WriteRowNames', true);
	filename = sprintf('yr%d_knf.csv', year);
    writetable(knfData, filename, 'WriteVariableNames', false, 'WriteRowNames', true);
	filename = sprintf('yr%d_knf_plasmepsin.csv', year);
    writetable(knfPlasmepsinData, filename, 'WriteVariableNames', false, 'WriteRowNames', true);
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

function [data] = get_frequency_data(directory, filter, dates) 
    % Get the files and prepare for the data
    files = dir(fullfile(directory, '*genotype-frequencies.csv'));
    frequency = zeros(length(files), 1);
    
    for ndx = 1:length(files)
        % Load the data
        filename = fullfile(files(ndx).folder, files(ndx).name);
        raw = readtable(filename, 'PreserveVariableNames', true);

        % Parse out the desired genotypes
        genotypes = table2array(unique(raw(:, 4)));                
        genotypes = genotypes(~cellfun('isempty', regexp(genotypes, filter, 'match')));
        
        % Get the data for the indicated date
        for date = dates
            data = raw(raw.days == date, :);
            for genotype = 1:size(genotypes)
                dataPoint = data(string(data.name) == genotypes(genotype), :);
                if ~isempty(dataPoint)
                    frequency(ndx) = frequency(ndx) + dataPoint.frequency;
                end
            end        
        end
    end
    
    % Transpose and return, note we are dividing by 12 due to 12 months
    % worth of data
    data = transpose(frequency ./ 12);
end
