function [] = save_figure(filename)
% Save the figure to disk

    % Determine the format
    if endsWith(filename, '.png')
        format = '-dpng';
    elseif endsWith(filename, '.tif') || endsWith(filename, '.tiff')
        format = '-dtiff';
    else
        error('Unknown image file extension');
    end

    % Save the image to disk
    set(gcf, 'Position',  [0, 0, 2560, 1440]);
    print(format, '-r300', filename);
    clf;
    close;
end