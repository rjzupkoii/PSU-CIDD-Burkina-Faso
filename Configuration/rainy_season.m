% Orginal equation
% y = a - min * sin((2 * pi / period) * t + (-phi * (2 * pi / period))))

% Simplified equation
% y = a + min * sin((2 * pi * (phi - t)) / period);

clear all;

hold on;

[short, short_rain] = seasonality(-0.9, -1.8, 140, 320, 0.1);
item(1) = plot(1:365, short);
%item(2) = plot(1:365, short_rain);

[long, long_rain] = seasonality(-0.9, -1.8, 132, 415, 0.1);
item(3) = plot(1:365, long);
%item(4) = plot(1:365, long_rain);

item(5) = xline(166, '-.', 'Approximate Start of Rainy Season', 'FontSize', 18);
item(6) = xline(274, '-.', 'Approximate End of Short Rainy Season', 'FontSize', 18);
item(7) = xline(305, '-.', 'Approximate End of Long Rainy Season', 'FontSize', 18);

legend(item([1 3]), 'Short Seasonality', 'Long Seasonality', 'FontSize', 18);

title('Seasonality of Malaira in Burkina Faso', 'fontsize', 32);
xlabel('Month', 'fontsize', 24);
ylabel('Beta Multiplier', 'fontsize', 24);
datetick('x', 'mmm');

plot = gca;
plot.FontSize = 18;

function [multiplier, rainy] = seasonality(a, b, phi, period, base)
    t = 1:365;
    multiplier = a + b * sin((2 * pi * (phi - t)) / period);
    multiplier(multiplier < 0) = 0;
    multiplier = base + multiplier;
    rainy = (multiplier > 0);
end