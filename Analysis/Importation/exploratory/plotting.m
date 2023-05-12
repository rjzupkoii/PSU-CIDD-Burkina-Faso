clear;

U5 = 0.8; O5 = 0.4;

data = readtable('data/seasonal-80-40.csv');
data = data(data.DaysElapsed > (11 * 365), :);
x = data.DaysElapsed;
predicted = ((data.ClinicalU5 * U5) + (data.ClinicalO5 * O5));


subplot(2, 1, 1);
hold on;
plot(x, data.Treatment, 'b');
plot(x, predicted, '--b');
ylabel('Treatments');

yyaxis right;
plot(x, (data.Treatment ./ data.ClinicalIndividuals) * 100.0, 'k');
ylabel('Percent Treatments');
ax = gca;
ax.YColor = 'k';

legend('Predicted', 'Model Treatments', 'Percent Treatments');
xlabel('Model Days');

subplot(2, 1, 2);
hold on;
plot(x, data.ClinicalU5, 'r');
plot(x, data.ClinicalU5 * U5, '--r');
plot(x, data.ClinicalO5, 'b');
plot(x, data.ClinicalO5 * O5, '--b');
plot(x, data.Treatment, 'k');
plot(x, predicted, '--k');

legend('Clinical U5', 'Clinical U5 / 80% Treated', 'Clinical O5', 'Clinical O5 / 40% Treated', 'Model Treatments', 'Predicted Treatments');
ylabel('Cases');
xlabel('Model Days');


function [] = theta_analysis()
    hold on;
    plot_theta('seasonal-50-50.csv');
    plot_theta('noseason-50-50.csv');
    plot_theta('seasonal-80-40.csv');
    plot_theta('noseason-80-40.csv');
    legend('Seasonal 50-50', 'Not Seasonal 50-50', 'Seasonal 80-40', 'Not Seasonal 80-40');
    ylabel('Theta');
    xlabel('Model Day');
end

function [] = plot_theta(filename)
    data = readtable(filename);
    data = data(data.DaysElapsed > (11 * 365), :);
    plot(data.DaysElapsed, data.Theta);
end
