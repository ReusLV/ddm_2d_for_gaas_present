figure;

% Assign different colors to nodes in different regions
% node_colors = zeros(length(x_coords), 3);
% for i = 1:length(x_coords)
%     if y_coords(i) <= H1  % Lower n+ region
%         node_colors(i,:) = [0, 0, 1];  % Blue
%     else  % Upper n region
%         node_colors(i,:) = [1, 0, 0];  % Red
%     end
% end

% Plot nodes
% scatter(x_coords, y_coords, 10, node_colors, 'filled');
hold on;

% Plot triangular elements
for i = 1:Nel
    nodes = el_2d_no(i,:);
    x_tri = x_coords(nodes);
    y_tri = y_coords(nodes);
    if el_mat_2d(i) == 1
        plot([x_tri; x_tri(1)], [y_tri; y_tri(1)], 'b-', 'LineWidth', 0.5);  % n+ region
    else
        plot([x_tri; x_tri(1)], [y_tri; y_tri(1)], 'r-', 'LineWidth', 0.5);  % n region
    end
end