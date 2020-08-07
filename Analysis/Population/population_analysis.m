% population_analysis.m
%
% Generate plots that allow us to compare how the model performs at scale.
clear;

global raw;
raw = csvread('data/population-full.csv', 1, 0);

%plot_population();
plot_error();

function [] = plot_error() 
    global raw;
    
    dayselapsed = unique(raw(:, 1));
    districts = unique(raw(:, 2));

    reference = csvread('data/weighted_pfpr.csv');

    colors = colormap(jet(size(districts, 1)));

    hold on;
    for district = transpose(districts)
        expected = reference(reference(:, 1) == district, 2);
        pfpr = raw(raw(:, 2) == district, 6);
        error = ((pfpr - expected) / expected) * 100;
        scatter(dayselapsed, error, 30, colors(district, :), 'Filled');    
    end 

    yline(0, '-.');
    xline(4000, '-.', 'Model Burn-in', 'FontSize', 18, 'LabelVerticalAlignment', 'bottom');

    title('Expected PfPr_{2 to 10} versus Simulated');
    ylabel('Percent Error');
    xlabel('Days Elapsed');

    hold off;
end

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
