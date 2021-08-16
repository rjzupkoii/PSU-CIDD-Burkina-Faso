function [] = plot_importation(filename, symptomatic, mutations, imports)
%PLOT_IMPORTATION Generate a 12 month plot based upon input parameters.
   
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
    data.year = arrayfun(@(n)addtodate(datenum('2007-1-1'), n, 'day'), data.dayselapsed);
    xlimit = [min(data.year) max(data.year)];
        
    % Generate the subplots
    for month = unique(data.month)'    
        subplot(3, 4, month);
        hold on;
        plot_replicates(data(data.month == month, :), month, xlimit, ylimit);
        title(datestr(datetime(1, month, 1), 'mmmm'));
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

function [] = plot_replicates(data, month, xlimit, ylimit)

    % Add the replicates to the plot
    for id = unique(data.replicateid)'
        replicate = data(data.replicateid == id, :);
        plot(replicate.year, replicate.frequency);
    end
    
    % Add the markers
    add_import_month(replicate.year, month);
    add_rainy_season(replicate.year, ylimit);
    
    % Format the subplot
    xlim(xlimit);
    ylim(ylimit);
    datetick('x', 'yyyy', 'keepticks', 'keeplimits');
end

function [] = add_import_month(days, month)
    days = unique(days);
    dates = [days str2num(datestr(datetime('2007-1-1') + days, 'mm'))];
    for ndx = dates(dates(:, 2) == month, 1)'
        xline(ndx, '-.');
    end
end

function [] = add_rainy_season(days, ylimit)

    % Get the unique dates and convert them to months
    days = unique(days);
    dates = [days str2num(datestr(datetime('2007-1-1') + days, 'mm'))];

    % Filter the start and end dates
    startdate = dates(dates(:, 2) == 6, 1);
    enddate = dates(dates(:, 2) == 10, 1);
        
    % Generate the patches
    for ndx = 1:size(startdate, 1)
        patch([startdate(ndx) enddate(ndx) enddate(ndx) startdate(ndx)], ...
            [ylimit(1) ylimit(1) ylimit(2) ylimit(2)], [230, 237, 247] / 255, 'LineStyle', 'none');
    end
    set(gca, 'children', flipud(get(gca,'children')));
end

function [result] = yesno(value)
    result = 'yes';
    if value == 0; result = 'no'; end
end
