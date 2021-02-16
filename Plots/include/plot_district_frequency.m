% plot_district_frequency.m
%
% This function generates frequency plots at a district level based upon 
% the data files in the supplied directory.


% Main entry point for the function, scans the supplied directory for
% subdirectories organized by mutation rate.
function [] = plot_district_frequency(directory, startDate)
    files = dir(directory);
    for ndx = 1:length(files)
        % Skip anything that is not the directories we are looking for
        if ~files(ndx).isdir, continue; end
        if strcmp(files(ndx).name(1), '.'), continue; end
                
        % Plot the national summary and district summary
        filename = fullfile(files(ndx).folder, files(ndx).name);
        [plotTitle, file] = parse_name(files(ndx).name);        
        generate(filename, startDate, plotTitle, file);
    end
end

% Generates a single plot based upon the data files in the supplyed
% subdirectory, saves the plot to disk.
function [] = generate(directory, startDate, plotTitle, file)   

    % Track the ymax so we can set all of the plots
    ymax = 0;

    files = dir(fullfile(directory, '*genotype-summary.csv'));
    for ndx = 1:length(files)
        
        % Load the data, note the unique days
        filename = fullfile(files(ndx).folder, files(ndx).name);
        data = csvread(filename, 1, 0);
        dn = prepareDates(filename, 2, startDate);
        
        % Load the replicates to the subplots based upon the district
        for district = transpose(unique(data(:, 3)))
            [name, sort] = getLocationName(district);
                        
            subplot(5, 9, sort);
            title(name);
            
            hold on;          
            plot(dn, data(data(:, 3) == district, 7) ./ data(data(:, 3) == district, 4));
            ymax = max(ymax, max(data(data(:, 3) == district, 7) ./ data(data(:, 3) == district, 4)));
            
            % Bit of a hack to make sure the date labels are correct
            xlim([min(dn), max(dn)]);            
        end        
    end
    
    % Apply the provience names and format the x-axis
    for ndx = 1:45
        subplot(5, 9, ndx);
        
        % Format the date ticks to be year labels
        xtl = {};
        for tick = get(gca, 'XTick'), xtl{end + 1} = datestr(tick, 'yyyy'); end
        set(gca, 'XTickLabel', xtl);
        
        % Format the y-axis range
        ylim([0 ymax]);
        
        hold off;
    end
    
    % Apply the common labels
    handle = axes(gcf, 'visible', 'off'); 
    handle.XLabel.Visible = 'on';
    handle.YLabel.Visible = 'on';
	handle.FontSize = 24;
    ylabel(handle, '580Y Frequency');
    xlabel(handle, 'Model Year');
    
    % Apply the title
    sgtitle({sprintf('580Y Frequency %s (%d Replicates)', ...
        plotTitle, length(files))}, 'FontSize', 24);
    
    % Save and close
    set(gcf, 'Position',  [0, 0, 2560, 1440]);
    print('-dtiff', '-r300', sprintf('out/%s-frequency-districts.png', file));
    clf;
    close;  
end