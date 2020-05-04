% Generate a plot that compares all of the Rho values
addpath('../Common');

% Prepare to run
files = dir(fullfile('archive', 'rho-*.zip'));
results = zeros(4, length(files));

% Load the survey data
PROVINCES = { 14, 'Kadiogo'; 16, 'Kourweogo'; 21, 'Bazega' };
survey = zeros(3, 45);
for ndx = 1:3
    survey(ndx, :) = getSurveyPoints(PROVINCES{ndx, 1});
end

for rho = 1:length(files)
    
    % Note the rho value
    temp = strrep(files(rho).name, 'rho-', '');
    temp = strrep(temp, '.zip', '');
    results(1, rho) = str2double(temp);
    
    % Extract the files we need to work with
    file = fullfile('archive', files(rho).name);
    unzip(file, 'working');
    
    % Load the data
    path = fullfile('working', files(rho).name);
    path = strrep(path, '.zip', '');
    data = loadDirectory(path, true);

    % Get the matches for each provience
    for ndx = 1:3
        results(ndx + 1, rho) = compare(data, ndx, survey(ndx, :));
    end
end

% Clean-up
rmdir('working', 's');

% Plot the results
bar(results(2:end, :)');
set(gca, 'xtick', 1:36);
xticklabels(results(1, :));
xtickangle(45);
title('Model Results versus Survey Data');
ylabel("IQR Match Count");
xlabel("Rho Value");
legend('Kadiogo', 'Kourweogo', 'Bazega', 'Location', 'eastoutside');

function [matches] = compare(data, index, survey)
    RANGES = [ 0.025, 0.25, 0.5, 0.75, 0.975 ];
    
    % Load the ranges
    data = transpose(squeeze(data(index, :, :)));
    stats = zeros(5, 45);
    for ndx = 1:45
        stats(:, ndx) = quantile(data(:, ndx), RANGES);
    end
    
    % Count the number of times the survey falls within the IQR
    matches = 0;
    for ndx = 1:45
        point = survey(ndx);
        if stats(2, ndx) <= point && point <= stats(4, ndx)
            matches = matches + 1;
        end
    end
end