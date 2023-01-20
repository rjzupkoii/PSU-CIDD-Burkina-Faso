% cyclic_analysis.m
%
% This script contains the SQL queries and functions used to explore why
% the percentage of treatments exhibit a cyclic pattern of behavior. Data
% from the Burkina Faso PLOS GPH manuscript data set, as well as the Rwanda
% manuscript data set were used (retrived via the SQL queries).
clear;

%% Burkina Faso
%{ 
select r.id, md.dayselapsed, msd.location, msd.population, msd.infectedindividuals,
  msd.treatments, msd.clinicalepisodes, msd.pfpr2to10
from sim.replicate r
  inner join sim.monthlydata md on md.replicateid = r.id
  inner join sim.monthlysitedata msd on msd.monthlydataid = md.id
where r.configurationid = 17582
  and md.dayselapsed > (11 * 365)
  and msd.location in (14, 44)
order by md.dayselapsed
%}
% raw = readmatrix('data/bfa-working.csv');
% subplot(2, 1, 1);
% plot_treatment(raw(raw(:, 3) == 14, :), 'Kadiogo');
% subplot(2, 1, 2);
% plot_treatment(raw(raw(:, 3) == 44, :), 'Kossi');

%{
select md.dayselapsed, msd.*
from sim.monthlydata md
  inner join sim.monthlysitedata msd on msd.monthlydataid = md.id
where md.replicateid = 17640
  and md.dayselapsed > (11 * 365)
  and msd.population > 10000
order by msd.population desc 
%}
raw = readmatrix('data/bfa-cell.csv');
plot_cells(raw, 'Cell Population > 10000');


%% Rwanda
%{
select r.id, md.dayselapsed, msd.location, msd.population, msd.infectedindividuals,
  msd.treatments, msd.clinicalepisodes, msd.pfpr2to10
from sim.replicate r
  inner join sim.monthlydata md on md.replicateid = r.id
  inner join sim.monthlysitedata msd on msd.monthlydataid = md.id
where r.configurationid = 4027
  and md.dayselapsed > (11 * 365)
  and msd.location in (8, 17)
order by md.dayselapsed
%}
% raw = readmatrix('data/rwa-working.csv');
% subplot(2, 1, 1);
% plot_treatment(raw(raw(:, 3) == 8, :), 'Gasabo');
% subplot(2, 1, 2);
% plot_treatment(raw(raw(:, 3) == 17, :), 'Huye');


%% Function defintions
% Plot the treated percentage for each replicate in the data provided.
function [] = plot_treatment(data, label)
    hold on;
    for replicate = transpose(unique(data(:, 1)))
        filtered = data(data(:, 1) == replicate, :);
        plot(filtered(:, 2), (filtered(:, 6) ./  filtered(:, 7)) * 100.0);
    end
    xlabel('Model Day');
    ylabel('Precent Treated');
    title(label);
end

% Plot the treated percentage for each cell in the data provided.
function [] = plot_cells(data, label)
    hold on;
    for cell = transpose(unique(data(:, 3)))
        filtered = data(data(:, 3) == cell, :);
        plot(filtered(:, 2), (filtered(:, 6) ./  filtered(:, 7)) * 100.0);
    end
    xlabel('Model Day');
    ylabel('Precent Treated');
    title(label);
end
