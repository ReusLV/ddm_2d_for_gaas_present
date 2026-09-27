% Boundary nodes identification based on geometric definition
global st_no

% Create nodes matrix with x and y coordinates
nodes = [x_coords, y_coords];

% Initialize node status array, default all nodes are interior nodes (0)
st_no = zeros(1, Nnode);

% Set geometric boundary tolerance
tol = 1e-8;

% Get geometric boundaries
x_min = 0;
y_min = 0;
x_max = L_nn;
y_max = H1 + H2;

% Iterate through all nodes and check if they are on the boundary
for i = 1:Nnode
    x = nodes(i,1);
    y = nodes(i,2);
    
    % If the node is on any boundary, mark it as a boundary node (1)
    if abs(x - x_min) < tol || abs(y - y_min) < tol || abs(y - y_max) < tol
        st_no(i) = 1;
    end
    
    % If at the interface between two layers, it can also be a boundary point
    if abs(y - H1) < tol && x >= L_n && x <= L_nn
            st_no(i) = 1;
    end
    
    % If at the vertical interface between n+ and n regions, it's a boundary point
    if abs(x - L_nn) < tol && y <= H1
        st_no(i) = 1;
    end

    if abs(x - L_n) < tol && y <= y_max && y >= H1
        st_no(i) = 1;
    end
    
end

% Optional: Print boundary node count
fprintf('Number of boundary nodes: %d\n', sum(st_no));
fprintf('Total number of nodes: %d\n', Nnode);

% Draw boundary nodes directly here, without calling an external function
figure('Position', [100, 100, 800, 600]);
hold on;

% Find boundary nodes
boundary_indices = find(st_no == 1);

% Display boundary nodes with red dots
scatter(x_coords(boundary_indices), y_coords(boundary_indices), 20, 'r.', 'DisplayName', 'Boundary Nodes');

% Add title and labels
title('Boundary Nodes Distribution', 'FontSize', 14);
xlabel('X Coordinate (cm)', 'FontSize', 12);
ylabel('Y Coordinate (cm)', 'FontSize', 12);

% Adjust axes
axis equal;
grid on;

% Get geometric dimensions for setting axis range
x_max = max(L_nn, L_n);
y_max = H1 + H2;
xlim([-0.05*x_max, 1.05*x_max]);
ylim([-0.05*y_max, 1.05*y_max]);

hold off;
