% model_analysis.m
%
% Generate plots that allow us to compare how the model performs at scale 
% when working with seasonal and non-seasonal data.
addpath('../Common');
clear;

STARTDATE = '2007-1-1';
FILENAME = 'data/validation-data-0.02.csv';

% Figure one plot
plotSimuatedVsReferencePfPR(FILENAME);

% Plot the monthly PfPR values
function [] = monthlyPfPR(filename, startDate, single)
    % Load the data and reference data
    data = csvread(filename, 1, 0);
    reference = csvread('../Common/weighted_pfpr.csv');
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

% Plot the error in PfPR to the reference data, presuming that transmission
% is perennial.
function [] = perennialError(filename, startDate) 
    % Load the data and reference data
    data = csvread(filename, 1, 0);
    reference = csvread('../Common/weighted_pfpr.csv');
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

% Plot the error summary in PfPR to the reference data, presuming the
% transmission ie perennial.
function [] = perennialErrorSummary(filename) 
    % Load reference data
    reference = csvread('../Common/weighted_pfpr.csv');
    
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

% Generate the simuated versus reference PfPR values, which can be used as
% figure one for a manuscript.
function [] = plotSimuatedVsReferencePfPR(filename)
    % Load the reference data
    reference = csvread('../Common/weighted_pfpr.csv');

    % Load and trim the evaluation data to post-burn-in
    data = csvread(filename, 1, 0);
    data = data(data(:, 1) >= (11 * 365), :);
    districts = unique(data(:, 2));

    % Prepare the color map
    colors = colormap(parula(size(districts, 1)));

    hold on;
    for district = transpose(districts)
        expected = reference(reference(:, 1) == district, 2);
        pfpr = data(data(:, 2) == district, 6); 

        % We want the seasonal maxima, filter out the local maxima, once
        % this is done we should only have six points left
        maxima = pfpr(pfpr > mean(pfpr));
        maxima = maxima(maxima > maxima - std(maxima));
        maxima = findpeaks(maxima);

        pfpr = pfpr .* -1;
        minima = pfpr(pfpr > mean(pfpr));
        minima = minima(minima > minima - std(minima));
        minima = findpeaks(minima);

        % Plot from the maxima to the minima, connected by a line
        line([expected expected], [mean(maxima) abs(mean(minima))], 'color', [0, 0, 0, 0.25]);
        scatter(expected, mean(maxima), 75, colors(district, :), 'filled', 'MarkerEdgeColor', 'black');
        scatter(expected, abs(mean(minima)), 37.5, [99 99 99] / 255, 'filled');
    end
    hold off;

    % Plot the reference error lines
    data = get(gca, 'YLim');
    line([data(1) data(2)], [data(1)*1.05 data(2)*1.1], 'Color', [0.5 0.5 0.5], 'LineStyle', '-.');
    % text(data(2) * 0.9, data(2) + 0.5, '+10%', 'FontSize', 16);
    line([data(1) data(2)], [data(1)*1.05 data(2)*1.05], 'Color', [0.5 0.5 0.5], 'LineStyle', '-.');
    % text(data(2)* 0.95, data(2) + 0.5, '+5%', 'FontSize', 16);
    line([data(1) data(2)], [data(1)*0.95 data(2)*0.95], 'Color', [0.5 0.5 0.5], 'LineStyle', '-.');
    text(data(2), data(2) * 0.95, '-5%', 'FontSize', 16);
    line([data(1) data(2)], [data(1)*0.95 data(2)*0.9], 'Color', [0.5 0.5 0.5], 'LineStyle', '-.');
    text(data(2), data(2) * 0.9, '-10%', 'FontSize', 16);
    
    % Plot the reference center line
    line([data(1) data(2)], [data(1) data(2)], 'Color', 'black', 'LineStyle', '-.');
    text(data(2), data(2) + 0.5, '\pm0%', 'FontSize', 16);
    
    xlim([0 60]);
    ylim([0 60]);
    pbaspect([1 1 1]);
    
    ylabel('Simulated {\it Pf}PR_{2 to 10}, mean of peaks');
    xlabel('Reference {\it Pf}PR_{2 to 10}');

    title('Burkina Faso, Simuated versus Reference {\it Pf}PR_{2 to 10} values');

    graphic = gca;
    graphic.FontSize = 20;
end

% Plot the error summary in PfPR to the refernce data, presuming the
% transmission is seasonal.
function [] = seasonalError(filename, startDate)
    % Load the data and reference data
    data = csvread(filename, 1, 0);
    reference = csvread('../Common/weighted_pfpr.csv');
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

% Plot the error summary in PfPR to the refernece data, presuming the
% trasnmission is seasonal.
function [] = seasonalErrorSummary(filename)
    % Load reference data
    reference = csvread('../Common/weighted_pfpr.csv');
    
    % Load and trim the evaluation data to post-burn-in
    data = csvread(filename, 1, 0);
    data = data(data(:, 1) >= (11 * 365), :);
    districts = unique(data(:, 2));
            
    hold on;
    for district = transpose(districts)
        expected = reference(reference(:, 1) == district, 2);
        pfpr = data(data(:, 2) == district, 6);
        
        % We want the seasonal maxima, filter out the local maxima, once
        % this is done we should only have ten points left (i.e., number of
        % years)
        peaks = pfpr(pfpr > mean(pfpr));
        peaks = peaks(peaks > peaks - std(peaks));
        peaks = findpeaks(peaks);
        
        % Find the real error and SD
        error = peaks - expected;
        sd = std(error);
        mre = sum(error) / size(error, 1);
        scatter(mre, sd, 45, 'filled');
        name = getLocationName(district);
        text(mre + 0.02, sd + 0.01, name, 'FontSize', 18);
    end
            
    title('Simulated vs. Expected {\it Pf}PR_{2 to 10} on a Seasonal Basis (Post Burn-in)', 'FontSize', 28);
    xlabel('Mean Difference in Peak {\it Pf}Pr_{2 to 10} Relative to Reference Value');
    ylabel('Standard Deviation for Ten Years');
    
    graphic = gca;
    graphic.FontSize = 24;
    hold off;
end

% Plot the population of individuals in the model from the start date.
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
