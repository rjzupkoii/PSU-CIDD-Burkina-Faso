% astmh.m
%
% Generate a summary 2 month plot based upon input parameters. This 
% function is intended largely to prepare some plots for a poster
% presentation at ASTMH 2021.
clear;

generate_astmh(@plot_astmh, 'data/old-data.csv', 'out/astmh-imports-%d.png');

function [] = generate_astmh(plotter, filename, imagename)
    fig = figure;

    for imports = [3 6 9]
        plotter(filename, 1, 0, imports);
    end 

    % Format the oveall plot
    handle = axes(fig, 'visible', 'off'); 
    handle.XLabel.Visible = 'on';
    handle.YLabel.Visible = 'on';
    ylabel(handle, '580Y Frequency (log_{10})');
    xlabel(handle, 'Model Year');
    set(gca, 'FontSize', 14);
    
    % Save the image to disk
%     set(gcf, 'Position',  [0, 0, 2560, 1440]);
%     image = sprintf(imagename, imports);
%     print('-dtiff', '-r300', image);
%     clf;
%     close;       
end

function [] = plot_astmh(filename, symptomatic, mutations, imports)
    % Filter the data
    data = readtable(filename, 'PreserveVariableNames', true);
    data = data(data.symptomatic == symptomatic, :);
    data = data(data.mutations == mutations, :);
    data = data(data.imports == imports, :);

    % Calculate the frequency
    data.frequency = log10(data.weightedoccurrences ./ data.infectedindividuals);

    % Update the dates
    dates = arrayfun(@(n)addtodate(datenum('2007-1-1'), n, 'day'), unique(data.dayselapsed));

    % Generate the subplots
    ndx = imports / 3;
    for month = [3 10]

        % Extract the data
        values = [];
        for replicate = unique(data(data.month == month, :).replicateid)'
            values = [values; data(data.replicateid == replicate, :).frequency'];
        end

        % Generate the plot
        subplot(2, 3, ndx);
        
        hold on;
        plot(dates, quantile(values, 0.25), 'LineStyle', ':', 'LineWidth', 1.5, 'color', [99 99 99] / 256.0);
        plot(dates, median(values), 'black', 'LineWidth', 2);
        plot(dates, quantile(values, 0.75), 'LineStyle', ':', 'LineWidth', 1.5, 'color', [99 99 99] / 256.0);
        
        % Format the plot
        title(sprintf('%s (%d imports)', datestr(datetime(1, month, 1), 'mmmm'), imports), 'FontWeight', 'Normal');
        set(gca, 'FontSize', 16);
        axis tight;
        ylim([-7 -3]);
        datetick('x', 'yyyy', 'keepticks', 'keeplimits');
        
        ndx = ndx + 3;
    end
end
