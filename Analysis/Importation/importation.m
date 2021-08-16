% importation.m
%
% Analysis script to determine the role that seasonality has on genotype
% fixation following importation.
clear;

for imports = 3:3:9
    for symptomatic = 0:1
        for mutations = 0:1
            % filename, symptomatic, mutations, imports
            plot_importation('data/data.csv', symptomatic, mutations, imports);
            
            % Save the image to disk
            set(gcf, 'Position',  [0, 0, 2560, 1440]);
            image = sprintf('out/import-%d-symptomatic-%d-mutations-%d.png', ... 
                imports, symptomatic, mutations);
            print('-dtiff', '-r300', image);
            clf;
            close;               
        end
    end
end


