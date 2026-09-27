% This function visualizes the boundary nodes
% Simplified version - only shows boundary points

function plot_boundary_nodes
    % Get global variables
    global x_coords y_coords st_no Nnode L_nn L_n H1 H2
    
    % Create new figure
    figure('Position', [100, 100, 800, 600]);
    
    % Plot boundary nodes
    hold on;
    
    % Find boundary nodes
    boundary_indices = find(st_no == 1);
    
    % Check if there are boundary nodes
    if isempty(boundary_indices)
        title('No boundary nodes found!', 'FontSize', 14, 'Color', 'r');
    else
        % Display boundary nodes with red dots
        scatter(x_coords(boundary_indices), y_coords(boundary_indices), 20, 'r.', 'DisplayName', 'Boundary Nodes');
        
        % Add title and labels
        title('Boundary Nodes Distribution', 'FontSize', 14);
        xlabel('X Coordinate (cm)', 'FontSize', 12);
        ylabel('Y Coordinate (cm)', 'FontSize', 12);
        
        % Display boundary node statistics
        boundary_count = length(boundary_indices);
        total_count = Nnode;
        percentage = (boundary_count / total_count) * 100;
        
        x_max = max(L_nn, L_n);
        y_max = H1 + H2;
        
        text(0.05*x_max, 0.95*y_max, sprintf('Number of boundary nodes: %d (%.1f%%)', boundary_count, percentage), ...
            'FontSize', 12, 'BackgroundColor', [1 1 0.8]);
    end
    
    % Adjust axes
    axis equal;
    grid on;
    
    hold off;
end
