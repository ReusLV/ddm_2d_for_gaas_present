function plot_cutline(quantity, x_coords, y_coords, cut_coord, cut_type, n_samples)
% quantity: physical quantity (vector, one value per node)
% x_coords, y_coords: mesh node coordinates
% cut_coord: coordinate value of the cutline (e.g., x=0.5 or y=0.2)
% cut_type: 'x' for vertical cutline, 'y' for horizontal cutline
% n_samples: number of points to sample along the cutline

if nargin < 6
    n_samples = 100; % default number of samples
end

% Automatically set y-axis label based on the input variable name
quantity_name = inputname(1);
switch lower(quantity_name)
    case 'phi'
        y_label = 'Normalized Potential';
    case 'n_t'
        y_label = 'Normalized Electron concentration';
    case 'p_t'
        y_label = 'Normalized Hole concentration';
    case 'eabs'
        y_label = 'Normalized Electric field';
    otherwise
        y_label = quantity_name;
end

F = scatteredInterpolant(x_coords(:), y_coords(:), quantity(:), 'linear', 'none');

if cut_type == 'x'
    y_min = min(y_coords);
    y_max = max(y_coords);
    yq = linspace(y_min, y_max, n_samples);
    xq = cut_coord * ones(size(yq));
    cutline_quantity = F(xq, yq);
    figure;
    plot(yq, cutline_quantity, 'o-');
    xlabel('y');
    ylabel(y_label);
    title(['Interpolated cutline at x = ', num2str(cut_coord)]);
elseif cut_type == 'y'
    x_min = min(x_coords);
    x_max = max(x_coords);
    xq = linspace(x_min, x_max, n_samples);
    yq = cut_coord * ones(size(xq));
    cutline_quantity = F(xq, yq);
    figure;
    plot(xq, cutline_quantity, 'o-');
    xlabel('x');
    ylabel(y_label);
    title(['Interpolated cutline at y = ', num2str(cut_coord)]);
else
    error('cut_type must be ''x'' or ''y''');
end
grid on;
end