% importation.m
%
% Analysis script to determine the role that seasonality has on genotype
% fixation following importation.
addpath('include');
clear;

generate(@plot_importation_replicates, 'data/bfa-merged.csv', 'out/imports-%d-symptomatic-%d-mutations-%d.png');
generate(@plot_importation_stats, 'data/bfa-merged.csv', 'out/summary-%d-symptomatic-%d-mutations-%d.png');

function [] = generate(plotter, filename, imagename)
    for imports = 3:3:9
        for symptomatic = 0:1
            for mutations = 0:1
                % Render the image
                plotter(filename, symptomatic, mutations, imports);
                                                
                % Save the image to disk
                set(gcf, 'Position',  [0, 0, 2560, 1440]);
                image = sprintf(imagename, imports, symptomatic, mutations);
                print('-dpng', '-r300', image);
                clf;
                close;               
            end
        end
    end 
end
