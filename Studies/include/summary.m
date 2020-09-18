% summary.m
%
% This function generates plots based upon the summary input files

% Generate plots based upon the summary input files
function [] = summary(directory, startDate)
    files = dir(directory);
    for ndx = 1:length(files)
        % Skip anything that is not the directories we are looking for
        if ~files(ndx).isdir, continue; end
        if strcmp(files(ndx).name(1), '.'), continue; end

        % Plot the national summary and district summary
        filename = fullfile(files(ndx).folder, files(ndx).name);
        plotDistrictSummary(filename, files(ndx).name, startDate);
        plotNationalSummary(filename, files(ndx).name, startDate);
    end
end

function [] = plotDistrictSummary(directory, rate, startDate)
    LOCATION_PATH = '../Analysis/Population/include/bfa_locations.csv';
    
    files = dir(fullfile(directory, '*.csv'));
    for ndx = 1:length(files)
        
        % Load the data, note the unique days
        filename = fullfile(files(ndx).folder, files(ndx).name);
        data = csvread(filename, 1, 0);
        dn = prepareDates(filename, 2, startDate);
        
        % Load the replicates to the subplots based upon the district
        for district = transpose(unique(data(:, 3)))
            subplot(5, 9, district);
            hold on;          
            plot(dn, data(data(:, 3) == district, 7) ./ data(data(:, 3) == district, 4));
            
            % Bit of a hack to make sure the date labels are correct
            xlim([min(dn), max(dn)]);            
        end        
    end
    
    % Apply the provience names and format the x-axis
    for ndx = 1:45
        subplot(5, 9, ndx);
        title(getLocationName(LOCATION_PATH, ndx));
        
        % Format the date ticks to be year labels
        xtl = {};
        for tick = get(gca, 'XTick'), xtl{end + 1} = datestr(tick, 'yyyy'); end
        set(gca, 'XTickLabel', xtl);     
        
        hold off;
    end
    
    % Apply the common labels
    handle = axes(gcf, 'visible', 'off'); 
    handle.XLabel.Visible = 'on';
    handle.YLabel.Visible = 'on';
	handle.FontSize = 18;
    ylabel(handle, '580Y Frequency');
    xlabel(handle, 'Model Year');
    sgtitle(sprintf('580Y Frequency Development with %s Mutation Rate', rate), 'FontSize', 24);
    
    % Save and close
    set(gcf, 'Position', get(0, 'Screensize'));    
	saveas(gcf, sprintf('out/%s-frequency-districts.png', rate));
    clf;
    close;  
end

% Generate a single freqeuncy plot that contains all of the replicates in
% the provided file
function [] = plotNationalSummary(directory, rate, startDate)
    
    hold on;
    
    replicates = 0;
    files = dir(fullfile(directory, '*.csv'));
    for ndx = 1:length(files)
        % Load the data, note the unique days
        filename = fullfile(files(ndx).folder, files(ndx).name);
        data = csvread(filename, 1, 0);
        days = transpose(unique(data(:, 2)));
        
        % Allocate the arrays
        frequency = zeros(size(days, 2), 1);
        occurrences = zeros(size(days, 2), 1);
        
        % Get the data, format the date in the process
        for ndy = 1:length(days)
            frequency(ndy) = sum(data(data(:, 2) == days(ndy), 7)) / sum(data(data(:, 2) == days(ndy), 4));
            occurrences(ndy) = sum(data(data(:, 2) == days(ndy), 5));
            days(ndy) = addtodate(datenum(startDate), days(ndy), 'day');
        end
                
        % Plot the data
        yyaxis left;
        plot(days, frequency, '-');
        yyaxis right;
        plot(days, log10(occurrences), '.-');
        
        % Update the replicate count
        replicates = replicates + 1;
    end
    
    hold off;

    % Add labels, title, apply formatting
    datetick('x', 'yyyy');
    xlabel('Model Year');
    yyaxis left;
    ylabel('580Y Frequency');
    yyaxis right;
    ylabel('Occurances of 580Y (log10)');    

    title({sprintf('580Y Frequency Development with %s Mutation Rate', rate), ...
        sprintf('3%% increase in treatment, %d replicates', replicates)});

    graphic = gca;
    graphic.FontSize = 18;
    
    % Save and close
    set(gcf, 'Position', get(0, 'Screensize'));
    saveas(gcf, sprintf('out/%s-frequency-replicates.png', rate));
    clf;
    close;    
end