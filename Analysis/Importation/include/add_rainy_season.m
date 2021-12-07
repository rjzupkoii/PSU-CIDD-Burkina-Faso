function [] = add_rainy_season(days, ylimit)
% Add the bounds of the rainy season to the plot

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