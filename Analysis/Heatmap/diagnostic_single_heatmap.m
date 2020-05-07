% diagnostic_single_heatmap.m
%
% Generate heatmaps for each of the months involved in the data set and
% plot them using the coordinates given for the raster.
FILENAME = 'data/rho-0.45-cellular.csv';
TRIPS = 4; SOURCE = 5; DESTINATION = 6;

% Load the data
data = csvread(FILENAME, 1, 0);
mapping = csvread('data/rho-0.45-district-map.csv', 1, 0);
X = 4; Y = 5;

% Prepare the "map" for the trips
rows = max(mapping(:, X) + 1);
cols = max(mapping(:, Y) + 1);

% Zero out the matrix
map = zeros(rows, cols);
    
% Note the interdistrict movement to the given location
for index = transpose(unique(data(:, DESTINATION)))
    row = mapping(mapping(:, 3) == index, X) + 1;
    col = mapping(mapping(:, 3) == index, Y) + 1;
    map(row, col) = sum(data(data(:, DESTINATION) == index, TRIPS));
end

% Plot the heatmap
hm = heatmap(map);
hm.Title = ["Modeled Trips to Desitnation Cell Cummulative for One Month"];
hm.XDisplayLabels = repmat(' ', cols, 1); 
hm.YDisplayLabels = repmat(' ', rows, 1);
grid off;
