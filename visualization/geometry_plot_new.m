figure;
hold on;

% Assign colors to nodes
node_colors = zeros(length(x_coords), 3);
for i = 1:length(x_coords)
    if y_coords(i) <= H1
        node_colors(i,:) = [0, 0, 1]; % Blue for n+
    else
        node_colors(i,:) = [1, 0, 0]; % Red for n
    end
end

% Plot elements
for i = 1:size(el_2d_no,1)
    nodes = el_2d_no(i,:);
    x_tri = x_coords(nodes);
    y_tri = y_coords(nodes);
    fill([x_tri x_tri(1)], [y_tri y_tri(1)], node_colors(nodes(1),:), 'EdgeColor', 'k', 'LineWidth', 0.2);
end

% Plot boundaries
plot([0 L_nn], [0 0], 'k-', 'LineWidth', 1);
plot([0 L_nn], [H1 H1], 'k-', 'LineWidth', 1);
plot([0 max(x_coords)], [H1+H2 H1+H2], 'k-', 'LineWidth', 1);
plot([0 0], [0 H1+H2], 'k-', 'LineWidth', 1);
plot([L_nn L_nn], [0 H1], 'k-', 'LineWidth', 1);
plot([max(x_coords) max(x_coords)], [H1 H1+H2], 'k-', 'LineWidth', 1);

xlabel('x [cm]');
ylabel('y [cm]');
ylim([-0.1*H1, H1+H2+0.1*H1]);
axis equal;
grid on;
box on;