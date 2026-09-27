function analyze_mesh(elements, x_coords, y_coords)
% analyze_mesh - Analyzes the quality of a 2D triangular mesh.
%
% Syntax: analyze_mesh(elements, x_coords, y_coords)
%
% Inputs:
%   elements - Nel x 3 matrix where each row contains the node indices of a triangle.
%   x_coords - Nnode x 1 vector of node x-coordinates.
%   y_coords - Nnode x 1 vector of node y-coordinates.

    num_elements = size(elements, 1);
    areas = zeros(num_elements, 1);

    % Calculate the area of each triangle
    for i = 1:num_elements
        nodes = elements(i, :);
        p1 = [x_coords(nodes(1)), y_coords(nodes(1))];
        p2 = [x_coords(nodes(2)), y_coords(nodes(2))];
        p3 = [x_coords(nodes(3)), y_coords(nodes(3))];
        
        % Area of a triangle using coordinates
        areas(i) = 0.5 * abs(p1(1)*(p2(2)-p3(2)) + p2(1)*(p3(2)-p1(2)) + p3(1)*(p1(2)-p2(2)));
    end

    % Display statistics
    fprintf('--- Mesh Quality Analysis ---\n');
    fprintf('Number of elements: %d\n', num_elements);
    fprintf('Element area statistics (in cm^2):\n');
    fprintf('  Max area:  %e\n', max(areas));
    fprintf('  Min area:  %e\n', min(areas));
    fprintf('  Mean area: %e\n', mean(areas));
    fprintf('  Std dev:   %e\n', std(areas));
    fprintf('-----------------------------\n');

    % Plot histogram of element areas
    figure('Name', 'Element Area Distribution');
    histogram(areas, 50);
    title('Histogram of Element Areas');
    xlabel('Element Area (cm^2)');
    ylabel('Frequency');
    set(gca, 'XScale', 'log'); % Use a log scale for better visualization
    grid on;

end 