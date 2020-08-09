% population_analysis.m
%
% Generate plots that allow us to compare how the model performs at scale.
clear;

global raw reference;
raw = csvread('data/population-full.csv', 1, 0);
reference = csvread('data/weighted_pfpr.csv');

plot_population();
%plot_error();
%plot_error_summary();

function [] = plot_error_summary() 
    global raw reference;

    % Trim off all of the data prior to burn-in
    data = raw(raw(:, 1) >= 4000, :);
    districts = unique(data(:, 2));

    hold on;
    for district = transpose(districts)
        expected = reference(reference(:, 1) == district, 2);
        pfpr = data(data(:, 2) == district, 6);
        values = (pfpr - expected) / expected;
        variance = var(values) * 100;
        error = sum(values) / size(values, 1) * 100;
        scatter(error, variance, 'filled');
        text(error + 0.025, variance + 0.0005, cellstr(num2str(district)));
    end

    title('Population Scaling versus Expected Values (Post-Burn-in)');
    xlabel('Mean Percent Error');
    ylabel('Error Variance');

    graphic = gca;
    graphic.FontSize = 18;
    hold off;
end

function [] = plot_error() 
    global raw reference;
    
    dayselapsed = unique(raw(:, 1));
    districts = unique(raw(:, 2));

    hold on;
    colors = colormap(parula(size(districts, 1)));
    for district = transpose(districts)
        expected = reference(reference(:, 1) == district, 2);
        pfpr = raw(raw(:, 2) == district, 6);
        error = ((pfpr - expected) / expected) * 100;
        scatter(dayselapsed, error, 50, colors(district, :), 'Filled');    
    end 

    yline(0, '-.');
    xline(4000, '-.', 'Model Burn-in', 'FontSize', 18, 'LabelVerticalAlignment', 'bottom');

    title('Expected PfPr_{2 to 10} versus Simulated');
    ylabel('Percent Error');
    xlabel('Days Elapsed');

    graphic = gca;
    graphic.FontSize = 18;
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
    graphic = gca;
    graphic.FontSize = 18;    
end
