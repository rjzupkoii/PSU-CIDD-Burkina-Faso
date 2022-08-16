function [] = save_figure(filename, retain)
% Save the figure to disk

    if ~exist('retain', 'var')
        retain = false;
    end

    % Determine the format
    if endsWith(filename, '.png')
        format = '-dpng';
    elseif endsWith(filename, '.tif') || endsWith(filename, '.tiff')
        format = '-dtiff';
    elseif endsWith(filename, '.svg')
        format = '-dsvg';
    else
        error('Unknown image file extension');
    end

    % Save the image to disk
    set(gcf, 'Position',  [0, 0, 2560, 1440]);
    print(format, '-r300', filename);
    if ~retain
        clf;
        close;
    end
end