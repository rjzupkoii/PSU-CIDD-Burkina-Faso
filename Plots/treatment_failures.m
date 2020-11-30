% treatment_failures.m
%
% Plot the treatment failures from the model.
addpath('../Analysis/Common');
addpath('include');
clear;

STARTDATE = '2007-1-1';

raw = csvread('data/treatment-failures.csv', 1, 0);
dn = transpose(prepareDates('data/treatment-failures.csv', 3, STARTDATE));

mapping = readtable('data/id-mapping.csv');
colors = colormap(lines(size(mapping, 1)));

labels = {};

hold on;
for row = 1:size(mapping)
    id = table2array(mapping(row, 1));
    for replicate = unique(raw(raw(:, 1) == id, 2))'
        data = raw(raw(:, 1) == id, :);
        data = data(data(:, 2) == replicate, :);
        plot(dn, data(:, 4), 'Color', colors(row, :));
    end
    
    % Parse out the name to use for the legend
    name = parse_name(string(strrep(table2cell(mapping(row, 2)), '.yml', '')));
    name = strrep(name, 'with ', '');
    labels = [labels, name];
end
add_legend(labels, colors);
hold off;

title('Comparison of Possible Interventions');
ylabel('Rate of Treatment Failures (population adjusted)');
datetick('x', 'yyyy');
xlabel('Model Year');

graphic = gca;
graphic.FontSize = 22;

function [] = add_legend(labels, colors)
    h = zeros(1, 1);
    index = 1;
    for label = labels
        h(index) = scatter(NaN, NaN, [], colors(index, :), 'filled');
        index = index + 1;
    end
	legend(h, cellstr(labels'), 'Location', 'NorthEast');
    legend boxoff;
end