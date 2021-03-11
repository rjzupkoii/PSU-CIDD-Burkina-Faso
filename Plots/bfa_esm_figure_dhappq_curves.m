% bfa_esm_figure_dhappq_curves.m
%
% This script generates Figure NN for the electronic supplmentary material
% for the Burkina Faso manuscript.
%
% NOTE that the data files are symlinked in from Dropbox.
clear;

subplot(2, 1, 1);
hold on;
add_data('DHA-PPQ_data/DP_0.051/_aggregate_data_0.csv');
add_data('DHA-PPQ_data/DP_0.100/_aggregate_data_0.csv');
add_data('DHA-PPQ_data/DP_0.150/_aggregate_data_0.csv');
add_data('DHA-PPQ_data/DP_0.200/_aggregate_data_0.csv');
hold off;
format_plot('Plasmepsin Double Copy Frequency, Usage Comparison', {'0.051 (Burkina Faso baseline)', '0.100', '0.150', '0.200'});

subplot(2, 1, 2);
add_data('DHA-PPQ_data/LongRun/_aggregate_data_0.csv');
format_plot('Plasmepsin Double Copy Frequency, Long Run', '0.051 (Burkina Faso baseline)');

function [] = add_data(filename)
    % Read and discard the first 4000 days of data (burn-in)
    data = csvread(filename, 1);
    data = data(data(:, 1) > 4000, :);

    % Parse the dates and plot
    dates = transpose(unique(data(:, 1)));
    for ndx = 1:size(dates, 2)
        dates(ndx) = addtodate(datenum('2007-1-1'), dates(ndx), 'day');
    end
    plot(dates, data(:, 11) ./ data(:, 3));  % Plasmepsin2xCopyWeighted
end

function [] = format_plot(plotTitle, legendItems)
    ylabel('Frequency');
    xlabel('Model Year');
    datetick('x', 'yyyy')

    legend(legendItems, 'Location', 'NorthWest');
    legend boxoff;
    title(plotTitle);
    axis tight;

    graphic = gca;
    graphic.FontSize = 18;
end