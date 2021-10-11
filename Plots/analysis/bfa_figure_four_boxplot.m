% bfa_figure_four.m
%
% Figure four plot comparing options for drug policies
clear;

PATH = '../Analysis/Loader/out';

fig = figure;

subplot(3, 3, 1);
add_boxplot(fullfile(PATH, 'bfa-fast-no-asaq'), 'Baseline');

subplot(3, 3, 2);
add_boxplot(fullfile(PATH, 'bfa-aldp10'), '10 year AL/DP MFT');

subplot(3, 3, 3);
add_boxplot(fullfile(PATH, 'bfa-aldp'), 'Rapid AL/DP MFT');

subplot(3, 3, 4);
add_boxplot(fullfile(PATH, 'bfa-tenyear'), '10 year Private Market Elimiation');

subplot(3, 3, 5);
add_boxplot(fullfile(PATH, 'bfa-aldp10-tenyear'), '10 year Private Market Elimiation, 10 year AL/DP MFT');

subplot(3, 3, 6);
add_boxplot(fullfile(PATH, 'bfa-aldp-tenyear'), '10 year Private Market Elimiation, Rapid AL/DP MFT');

subplot(3, 3, 7);
add_boxplot(fullfile(PATH, 'bfa-rapid'), 'Rapid Private Market Elimination');

subplot(3, 3, 8);
add_boxplot(fullfile(PATH, 'bfa-aldp10-rapid'), 'Rapid Private Market Elimination, 10 year AL/DP MFT');

subplot(3, 3, 9);
add_boxplot(fullfile(PATH, 'bfa-aldp-rapid'), 'Rapid Private Market Elimination, Rapid AL/DP MFT');

% Give common xlabel, ylabel and title to your figure
handle = axes(fig, 'visible', 'off'); 
handle.Title.Visible = 'on';
handle.XLabel.Visible = 'on';
handle.YLabel.Visible = 'on';
ylabel(handle, {'Treatment Failure Rate', ' '});
xlabel(handle, {' ', 'Model Year'});
title(handle, {'Drug Policy Options', ' '});
handle.FontSize = 20;


function [maxy] = add_boxplot(directory, plotTitle, maxy)
    hold on;
    files = dir(fullfile(directory, '*treatment-summary*'));
    
    dates = [6575 6606 6634 6665 6695 6726 6756 6787 6818 6848 6879 6909;
             8401 8432 8460 8491 8521 8552 8582 8613 8644 8674 8705 8735; 
             10227 10258 10286 10317 10347 10378 10408 10439 10470 10500 10531 10561];
         
    clinical = zeros(3, length(files)); % 2025 2030 2035
    failures = zeros(3, length(files));
    data = zeros(3, length(files));
    
    for ndx = 1:length(files)
        % Load the data
        filename = fullfile(files(ndx).folder, files(ndx).name);
        raw = csvread(filename, 1, 0);
        
        % Total the dates
        for row = 1:size(dates, 1)
            for date = dates(row, :)
                clinical(row, ndx) = clinical(row, ndx) + sum(raw(raw(:, 2) == date, 5));
                failures(row, ndx) = failures(row, ndx) + sum(raw(raw(:, 2) == date, 6));
            end
        end        
    end
    
    for ndx = 1:3
        data(ndx, :) = failures(ndx, :) ./ clinical(ndx, :);
    end
    data = transpose(data);
    boxplot(data, [2025 2030 2035]);
    ylim([0.04 0.22]);
    
    title(plotTitle);
    graphic = gca;
    graphic.FontSize = 14;
end
