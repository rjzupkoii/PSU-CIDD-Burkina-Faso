% cellular_studies.m
% 
% This script generates plots from the cellular data that was generted to
% isolate the cause of the cyclic pattern in the model results.

hold on;
files = dir('data/_aggregate_data*.csv');
for ndx = 1:length(files)
    filename = fullfile(files(ndx).folder, files(ndx).name);
    plot_aggregate(filename);
end

legend({'Sahelian zone (Short)', 'Sudano-Sahelian zone (Long)', 'Sudanian zone (Permanent)'});

ylabel('580Y Frequency');
xlabel('Days Elapsed');

title('Cellular Study - Burkina Faso Parameters - 79.4% starting treatment coverage');

axis tight;

graph = gca;
graph.FontSize = 18;

hold off;
    
function plot_aggregate(filename)
    DAYSELAPSED = 1; POPULATION = 2; INFECTEDINDIVIDUALS = 3;
    WEIGHTED = 5;

    data = csvread(filename, 1, 0);
    data = data(data(:, DAYSELAPSED) > 4000, :);

    % PfPR all
    %plot(data(:, DAYSELAPSED), data(:, INFECTEDINDIVIDUALS) ./ data(:, POPULATION));
    
    % 580Y weighted
    plot(data(:, DAYSELAPSED), data(:, WEIGHTED) ./ data(:, INFECTEDINDIVIDUALS));    
end