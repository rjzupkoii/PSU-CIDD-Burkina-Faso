function [] = save_figure(filename)
    set(gcf, 'Position',  [0, 0, 2560, 1440]);
    print('-dtiff', '-r300', filename);
    clf;
    close;
end