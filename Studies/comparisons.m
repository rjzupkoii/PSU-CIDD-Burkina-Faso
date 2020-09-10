addpath('../Analysis/Population/include');
clear;

FILENAME = 'data/comparison-treatmentfailures.csv';
STARTDATE = '2007-01-01';
SCALING = 0.25;

plotPopulation(FILENAME, STARTDATE, SCALING);
%plotTreatmentFailures(FILENAME, STARTDATE, SCALING);

function [] = plotPopulation(filename, startdate, scaling)
    raw = csvread(filename, 1, 0);
    
    hold on;
    rates = unique(raw(:, 1));
    for rate = transpose(rates)
        data = raw(raw(:, 1) == rate, :);
        
        % Prepare the dates
        dn = [];
        for value = transpose(data(:, 2))
            dn(end + 1) = addtodate(datenum(startdate), value, 'day');
        end 
        
        plot(dn, data(:, 3) ./ scaling ./ 1000000);
    end

    datetick('x', 'yyyy');
    set(gca, 'XLimSpec', 'Tight');

    title('Burkina Faso Population');
    ylabel('Population (Millions)');
    xlabel('Model Year');

    legend(cellstr(num2str(rates, '%g')), 'Location', 'NorthWest', 'NumColumns', 2);
    legend boxoff;

    graphic = gca;
    graphic.FontSize = 18;

    hold off;
end

function [] = plotTreatmentFailures(filename, startdate, scaling)
    raw = csvread(filename, 1, 0);

    hold on;
    rates = unique(raw(:, 1));
    for rate = transpose(rates)
        data = raw(raw(:, 1) == rate, :);
        
        % Prepare the dates
        dn = [];
        for value = transpose(data(2:end, 2))
            dn(end + 1) = addtodate(datenum(startdate), value, 'day');
        end

        % Prepare the treatment failures
        values = data(:, 5) ./ scaling ./ 100000;
        values = values(2:end) -  values(1:end - 1);
        
        plot(dn, values);
    end

    datetick('x', 'yyyy');
    set(gca, 'XLimSpec', 'Tight');

    title('Burkina Faso Treatment Failures vs. Increase in Treatment Coverage');
    ylabel('Treatment Failures (100,000''s)');
    xlabel('Model Year');

    legend(cellstr(num2str(rates, '%g')), 'Location', 'NorthWest', 'NumColumns', 2);
    legend boxoff;

    graphic = gca;
    graphic.FontSize = 18;

    hold off;
end