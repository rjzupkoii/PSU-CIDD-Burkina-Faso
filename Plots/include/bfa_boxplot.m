% create_boxplot.m
% 
% Plot the data proivded by the *_irq_calcluation.m scripts as a boxplot.

function [] = bfa_boxplot(data, labels, y_label)
    % Seperate the biological data from policy data
    bio = {};
    bio{end + 1} = cell2mat(data(1));
    bio{end + 1} = cell2mat(data(2));
    bio{end + 1} = cell2mat(data(7));
    add_plot(bio, 1, {labels{1:2} labels{7}}, "Biological Scenarios", y_label);

    % Remove the biological data from policy data
    data(7) = [];
    data(2) = [];
    data(1) = [];
    add_plot(data, 2, {labels{3:6} labels{8:end}}, "Policy Interventions", y_label);
end

% Add a boxplot to the plot already in progress at the given index with the
% given labels
function [] = add_plot(data, index, labels, plot_title, y_label)
    % Create the plot
    subplot(1, 2, index);
    indicies = num2cell(1:numel(data));
    temp = cellfun(@(x, y) [x(:) y*ones(size(x(:)))], data, indicies, 'UniformOutput', 0);
    temp = vertcat(temp{:});
    boxplot(temp(:,1), temp(:, 2), 'Labels', labels);
        
    % Format the plot
    title(plot_title);
    ylabel(y_label);
	graphic = gca;
    graphic.FontSize = 24;   
    set(gca, 'FontSize', 18, 'XTickLabelRotation', 15)   
end