% population_analysis.m
%
% Generate plots that allow us to compare how the model performs at scale.
clear;

global raw;
raw = csvread('data/population-full.csv', 1, 0);

%plot_population();

dayselapsed = unique(raw(:, 1));
districts = unique(raw(:, 2));

reference = csvread('data/weighted_pfpr.csv');

hold on;
for day = transpose(dayselapsed)
    data = raw(raw(:, 1) == day, :);
    for district = transpose(districts)
        expected = reference(reference(:, 1) == district, 2);
        pfpr = data(data(:, 2) == district, 6);
        error = 100 * (pfpr - expected) / expected;
        scatter(district, error);
    end
end 

title('Expected PfPr_{2 to 10} versus Simulated');
ylabel('Percent Error');
xlabel('District Identification Value');

hold off;


function [] = plot_population()
    global raw;

    % Extract the relevent raw
    dayselapsed = unique(raw(:, 1));
    population = [];
    for day = transpose(dayselapsed)
        population = [population, sum(raw(raw(:, 1) == day, 3))];
    end

    % Scale the raw back to full population
    population = population ./ 0.25;

    % Round off to millions
    population = population ./ 1000000;

    % Generate the population plot
    plot(dayselapsed, population);
    title('Growth of Simulated Population');
    ylabel('Population (millions)');
    xlabel('Days Elapsed');
end