% importation.m
%
% Analysis script to determine the role that seasonality has on genotype
% fixation following importation.
clear;

% All 580Y genotypes
generate('data/data.csv', 'out/allgenotypes-%d-symptomatic-%d-mutations-%d.png');

% TNY--Y1x genotypes only
generate('data/data-import.csv', 'out/tny--y1x-%d-symptomatic-%d-mutations-%d.png');

function [] = generate(filename, imagename)
    for imports = 3:3:9
        for symptomatic = 0:1
            for mutations = 0:1
                % filename, symptomatic, mutations, imports
                plot_importation(filename, symptomatic, mutations, imports);

                % Save the image to disk
                set(gcf, 'Position',  [0, 0, 2560, 1440]);
                image = sprintf(imagename, imports, symptomatic, mutations);
                print('-dtiff', '-r300', image);
                clf;
                close;               
            end
        end
    end
end