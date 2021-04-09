% bfa_esm_clinical_probablity.m
%
% Plot the range of Z values that adjust the clinical probablity of of
% symptoms.
clear;

p_max = 0.99;
p_min = 0.05;

% Range of Z values to plot
Z = [1 2:2:14];

% Prepare variable connected to Z range
labels = cell(1, size(Z, 2));
color = hsv(size(Z, 2));

% Bounds of the probablity
M = 0:0.01:1;
midpoint = 0.4;

% Plot all off the Z-value curves, note the legends
hold on;
ndx = 1;
for z= Z    
    p_clinical = (p_max  ./ ( 1 + (M / midpoint).^z ) ) ;
    plot(M, p_clinical, 'color', color(ndx,:), 'linewidth',1.3); 
    
    labels{1 ,ndx} = sprintf('z=%0.2f', z);
    ndx = ndx+1;
end 

xlabel('Immunity Level');
ylabel('Probability of developing symptoms');
legend(labels);
legend boxoff;

graphic = gca;
graphic.FontSize = 18;

jFrame = get(handle(gcf), 'JavaFrame');
jFrame.setMaximized(true);

set(gcf, 'Color', 'w');
