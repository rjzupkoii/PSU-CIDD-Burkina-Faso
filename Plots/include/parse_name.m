% parse_name.m
%
% Generate the name (title) and filename to use based upon the input filename 
function [name, file, label] = parse_name(file)
    prefix = strrep(file, '-frequency-map.csv', '');
    switch prefix
        case '0.0001983-bfa'
            name = 'with 0.0001983 Mutation Rate';
            file = 'de-novo-0.0001983';
            label = 'Slow Mutation Rate';
        case '0.001983-bfa'
            name = 'with 0.001983 Mutation Rate';
            file = 'de-novo-0.001983';
            label = 'Fast Mutation Rate';
        case 'bfa-import'
            name = 'with Importation Only';
            file = 'importation';
            label = 'Importation Only';
        case 'bfa-rapid'
            name = 'with Private Market Elimination (Immediate)';
            file = 'rapid';
            label = 'Public Market, Immediate';
        case 'bfa-vector'
            name = 'with Malaria Control Focus';
            file = 'vector';
            label = 'Malaria Control Focus';
        case 'bfa-fiveyear'
            name = 'with Private Market Elimination (5 years)';
            file = 'five';
            label = 'Public Market, 5 years';
        case 'bfa-tenyear'
            name = 'with Private Market Elimination (10 years)';
            file = 'ten';            
            label = 'Public Market, 10 years';
        case 'bfa-aldp-fiveyear'
            name = 'with AL/DP Balance (5 years)';
            file = 'aldp-fiveyear';
            label = 'AL/DP Balance, 5 years';
        case 'bfa-aldp-rapid'
            name = 'with AL/DP Balance (Immediate)';
            file = 'aldp-rapid';       
            label = 'AL/DP Balance, Immediate';
        otherwise
            error("No mapping for prefix %s", prefix);
    end
end

