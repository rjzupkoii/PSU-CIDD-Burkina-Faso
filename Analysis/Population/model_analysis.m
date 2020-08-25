% model_analysis.m
%
% Generate plots that allow us to compare how the model performs at scale 
% when working with seasonal and non-seasonal data.
clear;

% Load the data and prepare the dates
global raw reference;
start_date = '2006-1-1';
raw = csvread('data/population-seasonal.csv', 1, 0);
reference = csvread('data/weighted_pfpr.csv');
dn = prepare_dates(start_date);

%plot_population(dn);
%plot_error(start_date, dn);
plot_seasonal_error(start_date, dn);
%plot_error_summary(dn);

function [dn] = prepare_dates(start)
    global raw;
    
    dn = [];
    for days = unique(raw(:, 1))'
        dn(end+1) = addtodate(datenum(start), days, 'day');
    end
end

function [] = plot_error_summary(dn) 
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

function [] = plot_error(start_date, dn) 
    global raw reference;

    hold on;
    districts = unique(raw(:, 2));
    colors = colormap(parula(size(districts, 1)));
    for district = transpose(filtered)
        expected = reference(reference(:, 1) == district, 2);
        pfpr = raw(raw(:, 2) == district, 6);
        error = ((pfpr - expected) / expected) * 100;
        scatter(dn, error, 50, colors(district, :), 'Filled');    
    end 

    yline(0, '-.');
    start = addtodate(datenum(start_date), 4000, 'day');
    xline(start, '-.', 'Model Burn-in', 'FontSize', 18, 'LabelVerticalAlignment', 'bottom');

    datetick('x', 'yyyy');
    title('Expected PfPr_{2 to 10} versus Simulated');
    ylabel('Percent Error');
    xlabel('Days Elapsed');

    graphic = gca;
    graphic.FontSize = 18;
    hold off;
end

function [] = plot_seasonal_error(start_date, dn)
    global raw reference;
           
    % Prepare the color map
    colors = colormap(parula(size(unique(raw(:, 2)), 1)));
    
    % Prepare the burn-in marker point
    start = addtodate(datenum(start_date), 4000, 'day');
    
    % Iterate over the zones
    zones = unique(reference(:, 3));
    for zone = transpose(zones)
    
        % Filter and iterate over the districts
        districts = unique(reference(reference(:, 3) == zone, 1));
        subplot(3, 1, zone + 1);
        hold on;
        for district = transpose(districts)
            expected = reference(reference(:, 1) == district, 2);
            pfpr = raw(raw(:, 2) == district, 6);
            error = ((pfpr - expected) / expected) * 100;
            scatter(dn, error, 50, colors(district, :), 'Filled');    
        end 
        
        % At the plot features
        yline(0, '-.');
        xline(start, '-.', 'Model Burn-in', 'LabelVerticalAlignment', 'bottom');

        datetick('x', 'yyyy');
        title(sprintf('Expected PfPr_{2 to 10} versus Simulated (Zone {%d})', zone));
        ylabel('Percent Error');
        xlabel('Model Year');
        hold off;
    end

%    
end

function [] = plot_population(dn)
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
    plot(dn, population);
    
    % Format the plot
    datetick('x', 'yyyy');
    title('Growth of Simulated Population');
    ylabel('Population (millions)');
    xlabel('Days Elapsed');
    graphic = gca;
    graphic.FontSize = 18;    
end
