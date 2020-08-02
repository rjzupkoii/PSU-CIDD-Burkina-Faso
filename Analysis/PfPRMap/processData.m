clear all;

raw = csvread('data/population-scaling.csv', 1, 0);
districts = sort(transpose(unique(raw(:, 4))));
scales = sort(transpose(unique(raw(:, 1))));

hold on;
colors = colormap(jet(size(scales, 2)));
index = 1;
values = {};

for scale = scales
    data = raw(raw(:, 1) == scale, :);
    for district = districts
        timestep = data(data(:, 4) == district, 3);
        eir = data(data(:, 4) == district, 5);
        pfpr = data(data(:, 4) == district, 7);
        
        plot(timestep, pfpr, 'Color', colors(index, :));
    end
    index = index + 1;
end

xline(4000, '-.', 'Model Burn-in', 'FontSize', 18, 'LabelVerticalAlignment', 'middle');

addReference();
addLegend(scales, colors);

title('Population Scaling versus Expected PfPr_{2-10}');
xlabel('Model Timestep (days)');
ylabel('PfPr_{2-10} (Weighted Mean)');

plot = gca;
plot.FontSize = 18;

hold off;
    
function [] = addReference()
    % Ganzourgou
    %yline(30.9121 + 3.8835, '-.b', '', 'Color', 'black');
    yline(31.06, '--', 'Ganzourgou (31.06%)', 'Color', 'black', 'FontSize', 18, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom');
    %yline(30.9121 - 3.8835, '-.b', '', 'Color', 'black');

    % Oubritenga
    %yline(19.9553 + 3.3406, '-.b', '', 'Color', 'black');
    yline(19.03, '--', 'Oubritenga (19.03%)', 'Color', 'black', 'FontSize', 18, 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom');
    %yline(19.9553 - 3.3406, '-.b', '', 'Color', 'black');

    % Sanmatenga
    %yline(36.6661 + 11.9618, '-.b', '', 'Color', 'black');
    yline(32.93, '--', 'Sanmatenga (32.93%)', 'Color', 'black', 'FontSize', 18, 'LabelHorizontalAlignment', 'right');
    %yline(36.6661 - 11.9618, '-.b', '', 'Color', 'black');
end

% Create a custom legend
function [] = addLegend(labels, colors)
    h = zeros(1, 1);
    index = 1;
    for label = labels
        h(index) = plot(NaN, NaN, 'Color', colors(index, :));
        index = index + 1;
    end
    legend(h, cellstr(num2str(labels')), 'Orientation', 'horizontal', 'Location', 'south');
    legend boxoff;
end