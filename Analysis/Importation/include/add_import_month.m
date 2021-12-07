function [] = add_import_month(days, month)
% Add the marker for the import month to the plot

    days = unique(days);
    dates = [days str2num(datestr(datetime('2007-1-1') + days, 'mm'))];
    for ndx = dates(dates(:, 2) == month, 1)'
        xline(ndx, '-.');
    end
end