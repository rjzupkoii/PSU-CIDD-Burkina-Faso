% plot_maps.m
%
% Generate heatmaps based upon the loaded data.
clear;

FILENAME = 'data/rate-0.005-resistancefrequency.csv';
STARTDATE = '2007/1/1';
RATE = 0.005;

raw = csvread(FILENAME, 1, 0);
days = unique(raw(:, 1));

subplot(2, 2, 1);
generate(raw, days(1), STARTDATE);

subplot(2, 2, 2);
generate(raw, days(30), STARTDATE);

subplot(2, 2, 3);
generate(raw, days(60), STARTDATE);

subplot(2, 2, 4);
generate(raw, days(90), STARTDATE);

sgtitle(["Burkina Faso, artemisinin resistance frequency", sprintf("%g%% increase in coverage", RATE)]);

function [hm] = generate(raw, date, startDate)
    % Prepare the map
    rows = max(raw(:, 2) + 1);
    cols = max(raw(:, 3) + 1);
    map = zeros(rows, cols);

    data = raw(raw(:, 1) == date, :);
    for values = transpose(data)
        row = values(2) + 1;
        col = values(3) + 1;
        map(row, col) = values(4);    
    end
    
    days = addtodate(datenum(startDate), date, 'day');
    title = datestr(datetime(days, 'ConvertFrom', 'datenum'), 'mmmm yyyy');

    hm = heatmap(map);
    hm.Title = title;
    hm.XDisplayLabels = repmat(' ', cols, 1); 
    hm.YDisplayLabels = repmat(' ', rows, 1);
    hm.Colormap = colormap(flipud(hot));
    grid off;
end

