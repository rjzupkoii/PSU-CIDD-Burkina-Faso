% parse_name.m
%
% Generate the name (title) and filename to use based upon the input filename 
function [name, file, label] = parse_name(file)
    prefix = strrep(file, '-frequency-map.csv', '');
    switch prefix
        case '0.0001983-bfa'
            name = 'with 0.0001983 Mutation Rate';
            file = 'de-novo-0.0001983';
            label = 'Slow';
        case '0.001983-bfa'
            name = 'with 0.001983 Mutation Rate';
            file = 'de-novo-0.001983';
            label = 'Fast';
        case 'bfa-fast-no-asaq'
            name = 'with 0.001983 Muation Rate (no ASAQ)';
            file = 'de-novo-0.001983-no-asaq';
            label = 'Fast, no ASAQ';
        case 'bfa-rapid'
            name = 'with Private Market Elimination (Immediate)';
            file = 'rapid';
            label = 'Market';
        case 'bfa-tenyear'
            name = 'with Private Market Elimination (10 years)';
            file = 'ten';            
            label = 'Market, 10y';
        case 'bfa-aldp'
            name = 'with AL/DP MFT (Immediate)';
            file = 'aldp';
            label = 'AL/DP';
        case 'bfa-aldp10'
            name = 'with AL/DP MFT (10 years)';
            file = 'aldp10';
            label = 'AL/DP, 10 y';
        case 'bfa-aldp-tenyear'
            name = 'with AL/DP MFT (Immediate), Private Market Elimiation (10 years)';
            file = 'aldp-tenyear';
            label = 'AL/DP; Market, 10y';        
        case 'bfa-aldp-rapid'
            name = 'with AL/DP MFT (Immediate), Private Market Elimiation (Immediate)';
            file = 'aldp-rapid';       
            label = 'AL/DP; Market';
        case 'bfa-aldp10-rapid'
            name = 'with AL/DP MFT (10 years), Private Market Elimiation (Immediate)';
            file = 'aldp10-rapid';       
            label = 'AL/DP, 10y; Market';            
        case 'bfa-aldp10-tenyear'
            name = 'with AL/DP MFT (10 years), Private Market Elimiation (10 year)';
            file = 'aldp10-tenyear';       
            label = 'AL/DP, 10y; Market, 10y';              
        otherwise
            error("No mapping for prefix %s", prefix);
    end
end

