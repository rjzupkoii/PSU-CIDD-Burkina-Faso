% parse_name.m
%
% Generate the name (title) and filename to use based upon the input filename 
function [name, file] = parse_name(file)
    prefix = strrep(file, '-frequency-map.csv', '');
    switch prefix
        case '0.0001983-bfa'
            name = 'with 0.0001983 Mutation Rate';
            file = 'de-novo-0.0001983';
        case '0.001983-bfa'
            name = 'with 0.001983 Mutation Rate';
            file = 'de-novo-0.001983';
        case 'bfa-import'
            name = 'with Importation Only';
            file = 'importation';
        case 'bfa-rapid'
            name = 'with Rapid Private Market Elimination';
            file = 'rapid';
        case 'bfa-vector'
            name = 'with Malaria Control Focus';
            file = 'vector';
        case 'bfa-fiveyear'
            name = 'with Private Market Elimination (5 years)';
            file = 'five';
        case 'bfa-tenyear'
            name = 'with Private Market Elimination (10 years)';
            file = 'ten';            
        otherwise
            error("No mapping for prefix %s", prefix);
    end
end

