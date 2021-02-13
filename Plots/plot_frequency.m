% plot_frequency.m
%
% Generate a frequency plot of the provided genotype data.

clear;

% Load the data, get the unique dates and genotypes
dataset = readtable('testdata.csv', 'PreserveVariableNames', true);
dates = table2array(unique(dataset(:, 2)));
genotypes = table2array(unique(dataset(:, 4)));

% Find the distribution of the genotypes
years = zeros(size(dates, 1), 1);
distribution = zeros(size(dates, 1), size(genotypes, 1));
for genotype = 1:size(genotypes)
    data = dataset(string(dataset.name) == genotypes(genotype), :);
    for date = 1:size(dates)
        frequency = data(data.dayselapsed == dates(date), :);
        if isempty(frequency), continue, end
        distribution(date, genotype) = frequency.frequency;
        years(date) = str2double(frequency.year);
    end
end

% Plot the frequencies
pcolor(years, 1:size(genotypes), transpose(distribution))

% Create the colormap for the plot
cm = jet(10000);
cm = cm([1:100:3000 3007:7:10000], :);
cm(1, :)= [0.8 0.8 0.8];
colormap(cm);

% Set the shading for the plot
shading flat;
caxis([0 1]);

% Add the genotype codes to the y-axis
threshold = find(max(distribution) >= 0.001);
set(gca, 'YTick', threshold + 0.5 );
set(gca, 'YTickLabel', genotypes(threshold, :))

% Update the color bar
cb = colorbar('eastoutside');
cb.Label.String = 'Frequency';

% Add the table and set the font size
title('Frequency of Genotypes in Burkina Faso (Immediate MFT + Private Market Elimiation)');
graphic = gca;
graphic.FontSize = 16;
