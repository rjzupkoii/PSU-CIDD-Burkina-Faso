% plot_frequency_treatmentfailures.m
% 
% Plot the 580Y and plasmepsim double copy frequency versus the treatment
% failures at a national level.

clear;

frequencyTable = readtable('genotype-frequencies.csv', 'PreserveVariableNames', true);
dates = table2array(unique(frequencyTable(:, 2)));
genotypes = table2array(unique(frequencyTable(:, 4)));

% Filter the genotypes based upon the correct pattern
C580Y = '.....Y.';
PLASMEPSIN = '......2';

plasmespin = genotypes(~cellfun('isempty', regexp(genotypes, '......2', 'match')));
c580y = genotypes(~cellfun('isempty', regexp(genotypes, '.....Y.', 'match')));

summaryTable = readtable('treatment-summary.csv', 'PreserveVariableNames', true);

years = zeros(size(dates, 1), 1);
frequencyPlasmespin = zeros(size(dates, 1), 1);
frequency580Y = zeros(size(dates, 1), 1);
failures = zeros(size(dates, 1), 1);

for date = 1:size(dates)
    failures(date) = sum(summaryTable(summaryTable.days == dates(date), :).treatmentfailures);
    filtered = frequencyTable(frequencyTable.days == dates(date), :);
    for genotype = 1:size(plasmespin)
        frequency = filtered(string(filtered.name) == plasmespin(genotype), :);
        if isempty(frequency), continue, end
        frequencyPlasmespin(date) = frequencyPlasmespin(date) + frequency.frequency;
        years(date) = frequency.year;
    end
    for genotype = 1:size(c580y)
        frequency = filtered(string(filtered.name) == c580y(genotype), :);
        if isempty(frequency), continue, end
        frequency580Y(date) = frequency580Y(date) + frequency.frequency;
        years(date) = frequency.year;
    end    
    dates(date) = addtodate(datenum('2007-01-01'), dates(date), 'day');
end

hold on;
plot(dates, frequencyPlasmespin);
plot(dates, frequency580Y);
ylabel('Genotype Frequency');
yyaxis right;
plot(dates, failures);
ylabel('Treatment Failures');
hold off;

datetick('x', 'yyyy');
xlabel('Model Year');

title('Burkina Faso, Status Quo with no ASAQ');

legend({'Plasmepsin 2-3 2 Copy Frequency', '580Y Frequency', 'Treatment Failures'}, 'Location', 'NorthWest');
legend('boxoff');

graphic = gca;
graphic.YAxis(1).Color = 'black';
graphic.YAxis(2).Color = 'black';
graphic.FontSize = 16;