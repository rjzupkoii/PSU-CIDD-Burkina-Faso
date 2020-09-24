% getLocationName.m
%
% Get the location name from the file presuming the indicies are in index
% and the names are in column 3.
function [name] = getLocationName(filename, index)
    data = readtable(filename);
    name = string(table2cell(data(index, 3)));
end