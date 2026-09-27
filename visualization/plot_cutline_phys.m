function plot_cutline_phys(quantity_phys, x_coords_phys, y_coords_phys, cut_coord_cm, cut_type, n_samples)
% plot_cutline_phys - Cutline plot using physical units
% quantity_phys: vector at nodes (e.g., V, cm^-3, V/cm)
% x_coords_phys, y_coords_phys: node coordinates in cm
% cut_coord_cm: cut position in cm
% cut_type: 'x' (vertical cut at x=const) or 'y' (horizontal cut at y=const)
% n_samples: number of sample points along the cut

if nargin < 6
    n_samples = 100;
end

% Auto y-label based on variable name
qname = inputname(1);
switch lower(qname)
    case {'phi_phys','phi'}
        y_label = 'Potential (V)';
    case {'n_phys','n','n_t'}
        y_label = 'Electron concentration (cm^{-3})';
    case {'p_phys','p','p_t'}
        y_label = 'Hole concentration (cm^{-3})';
    case {'eabs_phys','eabs'}
        y_label = 'Electric field |E| (V/cm)';
    otherwise
        y_label = qname;
end

F = scatteredInterpolant(x_coords_phys(:), y_coords_phys(:), quantity_phys(:), 'linear', 'none');

if cut_type == 'x'
    fprintf('Cutline at x = %.4e cm\n', cut_coord_cm);
    y_min = 0;
    if cut_coord_cm < 15e-4
        y_max = 2.1e-4;
    else
        y_max = 2e-4;
    end
    yq = linspace(y_min, y_max, n_samples);
    xq = cut_coord_cm * ones(size(yq));
    cutline_quantity = F(xq, yq);
    figure;
    plot(yq, cutline_quantity, 'o-');
    xlabel('y (cm)');
    ylabel(y_label);
    title(['Cutline at x = ', num2str(cut_coord_cm), ' cm']);
elseif cut_type == 'y'
    x_min = 0;
    fprintf('Cutline at y = %.4e cm\n', cut_coord_cm);
    if cut_coord_cm < 2e-4
        x_max = 25e-4;
    else
        x_max = 15e-4;
    end
    xq = linspace(x_min, x_max, n_samples);
    yq = cut_coord_cm * ones(size(xq));
    cutline_quantity = F(xq, yq);
    figure;
    plot(xq, cutline_quantity, 'o-');
    xlabel('x (cm)');
    ylabel(y_label);
    title(['Cutline at y = ', num2str(cut_coord_cm), ' cm']);
else
    error('cut_type must be ''x'' or ''y''');
end
grid on;
end
