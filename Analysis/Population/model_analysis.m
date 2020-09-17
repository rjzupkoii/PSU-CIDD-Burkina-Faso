% model_analysis.m
%
% Generate plots that allow us to compare how the model performs at scale 
% when working with seasonal and non-seasonal data.
addpath('include');
clear;

STARTDATE = '2006-1-1';
FILENAME = 'data/population-seasonal-final.csv';

%plotPopulation(FILENAME, STARTDATE);

% Common to all types
%monthlyPfPR(FILENAME, STARTDATE, true);

% Seasonal exposure
%seasonalError(FILENAME, STARTDATE);
seasonalErrorSummary(FILENAME);

% Constant exposure
%perennialError(FILENAME, STARTDATE);
%perennialErrorSummary(FILENAME);

function [] = monthlyPfPR(filename, startDate, single)
    % Load the data and reference data
    data = csvread(filename, 1, 0);
    reference = csvread('data/weighted_pfpr.csv');
    dn = prepareDates(filename, 1, startDate);

    % Prepare the color map
    colors = colormap(parula(size(unique(data(:, 2)), 1)));
    
    % Prepare the burn-in marker point
    start = addtodate(datenum(startDate), 4000, 'day');
    
    % Iterate over the zones
    zones = unique(reference(:, 3));
    for zone = transpose(zones)
    
        % Filter and iterate over the districts
        districts = unique(reference(reference(:, 3) == zone, 1));
        if size(zones, 1) > 1 && not(single)
            subplot(size(zones, 1), 1, zone + 1);
        end
        
        % Select the correct plot format
        hold on;
        for district = transpose(districts)
            pfpr = data(data(:, 2) == district, 6);
            scatter(dn, pfpr, 50, colors(district, :), 'Filled');    
        end 
        
        % Add the plot features
        yline(0, '-.');
        xline(start, '-.', 'Model Burn-in', 'LabelVerticalAlignment', 'bottom');
        
        datetick('x', 'yyyy');
        xlim([min(dn) max(dn)])                
        ylabel('PfPR_{2 to 10}');
        xlabel('Model Year');

        % Adjust the title, fonts as needed
        if size(zones, 1) > 1 && not(single)
            title(sprintf('Simulated Monthly PfPr_{2 to 10} Over Time (Zone {%d})', zone));
        else
            title('Simulated Monthly PfPr_{2 to 10} Over Time');
            graphic = gca;
            graphic.FontSize = 18;
        end        

        hold off;
    end
end

function [] = perennialError(filename, startDate) 
    % Load the data and reference data
    data = csvread(filename, 1, 0);
    reference = csvread('data/weighted_pfpr.csv');
    dn = prepareDates(filename, 1, startDate);

    hold on;
    districts = unique(data(:, 2));
    colors = colormap(parula(size(districts, 1)));
    for district = transpose(districts)
        expected = reference(reference(:, 1) == district, 2);
        pfpr = data(data(:, 2) == district, 6);
        error = ((pfpr - expected) / expected) * 100;
        scatter(dn, error, 50, colors(district, :), 'Filled');    
    end 

    yline(0, '-.');
    start = addtodate(datenum(startDate), 4000, 'day');
    xline(start, '-.', 'Model Burn-in', 'FontSize', 18, 'LabelVerticalAlignment', 'bottom');

    datetick('x', 'yyyy');
    title('Expected PfPr_{2 to 10} versus Simulated');
    ylabel('Percent Error');
    xlabel('Days Elapsed');

    graphic = gca;
    graphic.FontSize = 18;
    hold off;
end

function [] = perennialErrorSummary(filename) 
    % Load reference data
    reference = csvread('data/weighted_pfpr.csv');
    
    % Load and trim the evaluation data to post-burn-in
    data = csvread(filename, 1, 0);
    data = data(data(:, 1) >= 4000, :);
    districts = unique(data(:, 2));

    hold on;
    for district = transpose(districts)
        expected = reference(reference(:, 1) == district, 2);
        pfpr = data(data(:, 2) == district, 6);
        values = (pfpr - expected) / expected;
        sd = std(values) * 100;
        error = sum(values) / size(values, 1) * 100;
        scatter(error, sd, 'filled');
        name = getLocationName('include/bfa_locations.csv', district);
        text(error + 0.025, sd + 0.0005, name);
    end

    title('Simulated vs. Expected PfPR on a Perennial Basis (Post-Burn-in)');
    xlabel('Mean Percent Error');
    ylabel('Standard Deviation');

    graphic = gca;
    graphic.FontSize = 18;
    hold off;
end

function [] = seasonalError(filename, startDate)
    % Load the data and reference data
    data = csvread(filename, 1, 0);
    reference = csvread('data/weighted_pfpr.csv');
    dn = prepareDates(filename, 1, startDate);

    % Prepare the color map
    colors = colormap(parula(size(unique(data(:, 2)), 1)));
    
    % Prepare the burn-in marker point
    start = addtodate(datenum(startDate), 4000, 'day');
    
    % Iterate over the zones
    zones = unique(reference(:, 3));
    for zone = transpose(zones)
    
        % Filter and iterate over the districts
        districts = unique(reference(reference(:, 3) == zone, 1));
        subplot(3, 1, zone + 1);
        hold on;
        for district = transpose(districts)
            expected = reference(reference(:, 1) == district, 2);
            pfpr = data(data(:, 2) == district, 6);
            error = pfpr - expected;
            %scatter(dn, error, 50, colors(district, :), 'Filled');    
            plot(dn, error, 50, colors(district, :));    
        end 
        
        % At the plot features
        yline(0, '-.');
        xline(start, '-.', 'Model Burn-in', 'LabelVerticalAlignment', 'bottom');

        datetick('x', 'yyyy');
        xlim([min(dn) max(dn)])
        title(sprintf('Expected PfPr_{2 to 10} versus Simulated (Zone {%d})', zone));
        ylabel('Percent Error Realative to Peak');
        xlabel('Model Year');
        hold off;
    end
end

function [] = seasonalErrorSummary(filename)
    % Load reference data
    reference = csvread('data/weighted_pfpr.csv');
    
    % Load and trim the evaluation data to post-burn-in
    data = csvread(filename, 1, 0);
    data = data(data(:, 1) >= (11 * 365), :);
    districts = unique(data(:, 2));
            
    hold on;
    for district = transpose(districts)
        expected = reference(reference(:, 1) == district, 2);
        pfpr = data(data(:, 2) == district, 6);
        
        % We want the seasonal maxima
        peaks = pfpr(pfpr > mean(pfpr));
        peaks = findpeaks(peaks);
        
        % Find the real error and SD
        error = peaks - expected;
        sd = std(error);
        mre = sum(error) / size(error, 1);
        scatter(mre, sd, 45, 'filled');
        name = getLocationName('include/bfa_locations.csv', district);
        text(mre + 0.02, sd + 0.01, name, 'FontSize', 18);
    end
            
    title('Simulated vs. Expected {\it PfPR_{2 to 10}} on a Seasonal Basis (Post Burn-in)', 'FontSize', 28);
    xlabel('Mean Difference in Peak {\it PfPr_{2 to 10}} Relative to Reference Value');
    ylabel('Standard Deviation');
    
    graphic = gca;
    graphic.FontSize = 24;
    hold off;
end

function [] = plotPopulation(filename, startDate)
    
    % Extract the relevent data
    data = csvread(filename, 1, 0);
    dayselapsed = unique(data(:, 1));
    population = [];
    for day = transpose(dayselapsed)
        population = [population, sum(data(data(:, 1) == day, 3))];
    end

    % Scale the raw back to full population
    population = population ./ 0.25;

    % Round off to millions
    population = population ./ 1000000;

    % Generate the population plot
    dn = prepareDates(filename, 1, startDate);
    plot(dn, population);
    
    % Format the plot
    datetick('x', 'yyyy');
    title('Growth of Simulated Population');
    ylabel('Population (millions)');
    xlabel('Days Elapsed');
    graphic = gca;
    graphic.FontSize = 18;    
end
