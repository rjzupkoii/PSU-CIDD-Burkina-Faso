function [] = plot_importation_stats(filename, symptomatic, mutations, imports)
%PLOT_IMPORTATION_STATS Generate a summary 12 month plot based upon input parameters.
   
    % Prepare the figure
    fig = figure;

    % Filter the data
    data = readtable(filename, 'PreserveVariableNames', true);
    data = data(data.symptomatic == symptomatic, :);
    data = data(data.mutations == mutations, :);
    data = data(data.imports == imports, :);

    % Calculate the frequency
    data.frequency = log10(data.weightedoccurrences ./ data.infectedindividuals);
    ylimit = [min(data(data.frequency > log10(0), :).frequency) max(data.frequency)];

    % Update the dates
    dates = arrayfun(@(n)addtodate(datenum('2007-1-1'), n, 'day'), unique(data.dayselapsed));
    xlimit = [min(dates) max(dates)];

    % Generate the subplots
    for month = 1:1:12

        % Extract the data
        values = [];
        for replicate = unique(data(data.month == month, :).replicateid)'
            values = [values; data(data.replicateid == replicate, :).frequency'];
        end

        % Generate the plot
        subplot(3, 4, month);
        hold on;
        plot(dates, quantile(values, 0.75), 'LineStyle', ':', 'color', [99 99 99] / 256.0);
        plot(dates, median(values), 'black');
        plot(dates, quantile(values, 0.25), 'LineStyle', ':', 'color', [99 99 99] / 256.0);

        % Format the plot
        title(datestr(datetime(1, month, 1), 'mmmm'));    
        xlim(xlimit);
        ylim(ylimit);
        datetick('x', 'yyyy', 'keepticks', 'keeplimits');
    end

    % Format the oveall plot
    handle = axes(fig, 'visible', 'off'); 
    handle.XLabel.Visible = 'on';
    handle.YLabel.Visible = 'on';
    ylabel(handle, '580Y Frequency (log_{10})');
    xlabel(handle, 'Model Year');
    
    sgtitle(sprintf('Importations: %d/mo, Symptomatic: %s, Mutations: %s', ...
        imports, yesno(symptomatic), yesno(mutations)), 'FontSize', 18);
    graphic = gca;
    graphic.FontSize = 18;
end
