

raw = readtable('../data/bfa-cellular.csv');
dates = unique(raw.dayselapsed);

ndx = 1;
for study = transpose(unique(raw.filename))
    data = raw(string(raw.filename) == study, :);

    subplot(2, 2, ndx);
    hold on;
    for replicate = transpose(unique(data.id))
        plot(dates, data(data.id == replicate, :).percent_treated);
    end
    ndx = ndx + 1;
end