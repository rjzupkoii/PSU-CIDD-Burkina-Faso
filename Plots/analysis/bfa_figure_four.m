% bfa_figure_four.m
%
% Figure four plot comparing options for drug policies
clear;

PATH = '../Analysis/Loader/out';

fig = figure;
maxy = 0;

subplot(3, 3, 1);
maxy = add_plot(fullfile(PATH, 'bfa-tenyear'), '10 year Private Market Elimiation', maxy);

subplot(3, 3, 2);
maxy = add_plot(fullfile(PATH, 'bfa-aldp-tenyear'), '10 year Private Market Elimiation, Rapid AL/DP MFT', maxy);

subplot(3, 3, 3);
maxy = add_plot(fullfile(PATH, 'bfa-aldp10-tenyear'), '10 year Private Market Elimiation, 10 year AL/DP MFT', maxy);

subplot(3, 3, 4);
maxy = add_plot(fullfile(PATH, 'bfa-rapid'), 'Rapid Private Market Elimination', maxy);

subplot(3, 3, 5);
maxy = add_plot(fullfile(PATH, 'bfa-aldp-rapid'), 'Rapid Private Market Elimination, Rapid AL/DP MFT', maxy);

subplot(3, 3, 6);
maxy = add_plot(fullfile(PATH, 'bfa-aldp10-rapid'), 'Rapid Private Market Elimination, 10 year AL/DP MFT', maxy);

subplot(3, 3, 7);
maxy = add_plot(fullfile(PATH, 'bfa-fast-no-asaq'), 'Baseline', maxy);

subplot(3, 3, 8);
maxy = add_plot(fullfile(PATH, 'bfa-aldp'), 'Rapid AL/DP MFT', maxy);

subplot(3, 3, 9);
maxy = add_plot(fullfile(PATH, 'bfa-aldp10'), '10 year AL/DP MFT', maxy);

for ndx = 1:9
    format_plot(ndx, maxy, '2007-1-1');
end

% Give common xlabel, ylabel and title to your figure
handle = axes(fig, 'visible', 'off'); 
handle.Title.Visible = 'on';
handle.XLabel.Visible = 'on';
handle.YLabel.Visible = 'on';
ylabel(handle, {'Treatment Failure Rate', ' '});
xlabel(handle, {' ', 'Model Year'});
title(handle, {'Drug Policy Options', ' '});
handle.FontSize = 20;

function [maxy] = add_plot(directory, plotTitle, maxy)
    hold on;
    files = dir(fullfile(directory, '*treatment-summary*'));
    for ndx = 1:length(files)
        % Load the data, clip the first 13 years off so that we start
        % displaying data with model year 2020
        filename = fullfile(files(ndx).folder, files(ndx).name);
        data = csvread(filename, 1, 0);
        data = data(data(:, 2) > 13 * 365, :);
        
        % Total each day
        days = transpose(unique(data(:, 2)));
        total = zeros(size(days, 1)); index = 1;
        for day = days
            total(index) = sum(data(data(:, 2) == day, 6)) / sum(data(data(:, 2) == day, 5));
            index = index + 1;
        end
        
        % Append the plot
        plot(days, total);
        
        % Update the maxy 
        maxy = max(maxy, max(total));
    end        

    hold off;
    title(plotTitle);
    axis tight;
end

function [] = format_plot(ndx, maxy, startDate)
    subplot(3, 3, ndx);
    ylim([0 maxy]);
    
    % Format the dates based upon the xaxis and ticks, this code might
    % break if the bounds change
    labels = [];
    for tick = xticks()
        tick = addtodate(datenum(startDate), tick, 'day');
        labels = [labels str2num(datestr(tick, 'yyyy'))];
    end
    set(gca, 'XTick', xticks(), 'XTickLabel', labels);
    
    % Set the font sizes
    graphic = gca;
    graphic.FontSize = 14;
end