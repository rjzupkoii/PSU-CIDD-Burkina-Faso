function [] = plot_importation_replicates(filename, symptomatic, mutations, imports)
%PLOT_IMPORTATION_REPLICATES Generate a 12 month plot of the replicates based upon input parameters.
   
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
