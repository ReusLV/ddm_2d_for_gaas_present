function plot_cutline_phys_mesh(V, x_coords, y_coords, el_2d_no, cut_coord_cm, cut_type, n_samples, mode, smooth)
% plot_cutline_phys_mesh - Cutline plot over an unstructured triangular mesh without global interpolation
% V:            quantity to sample along the cut, in physical units already
%               - nodal scalar (Nnode x 1), supports 'bary' or 'elemconst'
%               - element scalar (Nel x 1), uses element-constant sampling
% x_coords:     node x in cm (Nnode x 1)
% y_coords:     node y in cm (Nnode x 1)
% el_2d_no:     (Nel x 3) triangle connectivity (node indices)
% cut_coord_cm: cut position (x0 if cut_type='x', y0 if 'y'), in cm
% cut_type:     'x' (vertical cut x=x0) or 'y' (horizontal cut y=y0)
% n_samples:    number of sample points along the cut
% mode:         'bary' (FE shape functions) | 'elemconst' (element-constant)
%               Note: for element-based V, sampling is element-constant regardless of mode.
% smooth:       optional logical (default false); if true and V is element-based,
%               project element values to nodes by area-weighted averaging, then
%               sample using 'bary' for a smooth curve.

if nargin < 7 || isempty(n_samples), n_samples = 100; end
if nargin < 8 || isempty(mode), mode = 'bary'; end
if nargin < 9 || isempty(smooth), smooth = false; end

cut_type = lower(cut_type);
mode = lower(mode);

Nnode = numel(x_coords);
Nel   = size(el_2d_no,1);

% Infer whether V is nodal-based or element-based
if numel(V) == Nnode
    value_loc = 'node';
elseif numel(V) == Nel
    value_loc = 'elem';
else
    error('V length (%d) must match either Nnode (%d) or Nel (%d).', numel(V), Nnode, Nel);
end

% Optional smoothing: element -> node (area-weighted), then barycentric
did_smooth = false;
if smooth && strcmp(value_loc,'elem')
    V = local_elem_to_node_area_avg(el_2d_no, x_coords, y_coords, V);
    value_loc = 'node';
    mode = 'bary';
    did_smooth = true;
end

% Auto y-label based on input name
qname = inputname(1);
qlow = lower(string(qname));
switch qlow
    case {"phi_phys","phi"}
        y_label = 'Potential (V)';
    case {"n_phys","n","n_t"}
        y_label = 'Electron concentration (cm^{-3})';
    case {"p_phys","p","p_t"}
        y_label = 'Hole concentration (cm^{-3})';
    case {"eabs_phys","eabs"}
        y_label = 'Electric field |E| (V/cm)';
    otherwise
        % Heuristics for current density naming
        if contains(qlow, "jx")
            y_label = 'Current density J_x (A/cm^2)';
        elseif contains(qlow, "jy")
            y_label = 'Current density J_y (A/cm^2)';
        elseif contains(qlow, "jabs") || contains(qlow, "|j|") || strcmp(qlow,"j") || contains(qlow,"j_total") || contains(qlow,"jmag")
            y_label = 'Current density |J| (A/cm^2)';
        else
            y_label = qname;
        end
end

% Build sampling abscissa along the cut
switch cut_type
    case 'x' % vertical line x = const, sample along y
        if cut_coord_cm < 15e-4
            y_min = 0; y_max = 2.1e-4;
        else
            y_min = 0; y_max = 2e-4;
        end
        axis_vals = linspace(y_min, y_max, n_samples).';
        Xq = cut_coord_cm * ones(n_samples,1);
        Yq = axis_vals;
        xlab = 'y (cm)';
        title_txt = sprintf('Cutline at x = %.3g cm', cut_coord_cm);
    case 'y' % horizontal line y = const, sample along x
        if cut_coord_cm < 2e-4
            x_min = 0; x_max = 25e-4;
        else
            x_min = 0; x_max = 15e-4;
        end
        axis_vals = linspace(x_min, x_max, n_samples).';
        Xq = axis_vals;
        Yq = cut_coord_cm * ones(n_samples,1);
        xlab = 'x (cm)';
        title_txt = sprintf('Cutline at y = %.3g cm', cut_coord_cm);
    otherwise
        error('cut_type must be ''x'' or ''y''');
end

% Precompute triangle bounding boxes to accelerate point location
Nel = size(el_2d_no,1);
tri_minx = zeros(Nel,1); tri_maxx = zeros(Nel,1);
tri_miny = zeros(Nel,1); tri_maxy = zeros(Nel,1);
for i = 1:Nel
    nd = el_2d_no(i,:);
    tri_x = x_coords(nd); tri_y = y_coords(nd);
    tri_minx(i) = min(tri_x); tri_maxx(i) = max(tri_x);
    tri_miny(i) = min(tri_y); tri_maxy(i) = max(tri_y);
end

Vq = nan(n_samples,1);
found = false(n_samples,1);

% Helper to compute barycentric coordinates and FE evaluation
    function [inside, val] = eval_in_triangle(ix, xq, yq)
        nd = el_2d_no(ix,:);
        xv = x_coords(nd); yv = y_coords(nd);
        % Barycentric coordinates (area-based)
        denom = (yv(2) - yv(3))*(xv(1) - xv(3)) + (xv(3) - xv(2))*(yv(1) - yv(3));
        if abs(denom) < eps
            inside = false; val = NaN; return;
        end
        l1 = ((yv(2) - yv(3))*(xq - xv(3)) + (xv(3) - xv(2))*(yq - yv(3))) / denom;
        l2 = ((yv(3) - yv(1))*(xq - xv(3)) + (xv(1) - xv(3))*(yq - yv(3))) / denom;
        l3 = 1 - l1 - l2;
        tol = -1e-12; % small tolerance allows points on edges
        inside = (l1 >= tol) && (l2 >= tol) && (l3 >= tol);
        if ~inside
            val = NaN; return;
        end
        if strcmp(value_loc,'node')
            if strcmp(mode,'bary')
                val = l1*V(nd(1)) + l2*V(nd(2)) + l3*V(nd(3));
            else % 'elemconst' from nodal values (element average)
                val = (V(nd(1)) + V(nd(2)) + V(nd(3))) / 3;
            end
        else % element-based value -> element-constant sampling
            val = V(ix);
        end
    end

% For each query point, test triangles whose bbox contains it
for k = 1:n_samples
    xq = Xq(k); yq = Yq(k);
    cand = (xq >= tri_minx) & (xq <= tri_maxx) & (yq >= tri_miny) & (yq <= tri_maxy);
    idx = find(cand).';
    for ix = idx
        [inside, val] = eval_in_triangle(ix, xq, yq);
        if inside
            Vq(k) = val; found(k) = true; break;
        end
    end
end

% Optional: forward/backward fill small gaps (e.g., exactly on boundary)
if any(~found)
    % Simple gap fill with nearest found neighbor along the line
    id_found = find(found);
    if ~isempty(id_found)
        Vq = fillmissing(Vq, 'nearest');
    end
end

figure; plot(axis_vals, Vq, 'b-','LineWidth',1.6);
grid on; xlabel(xlab); ylabel(y_label); title(title_txt);

if strcmp(value_loc,'elem')
    legend_str = sprintf('elem-const, N=%d', n_samples);
else
    if did_smooth
        legend_str = sprintf('smooth-bary, N=%d', n_samples);
    else
        legend_str = sprintf('mode=%s, N=%d', mode, n_samples);
    end
end
legend(legend_str, 'Location','best');

end

% --- Local helper: element -> node area-weighted averaging ---
function node_vals = local_elem_to_node_area_avg(el_2d_no, x_coords, y_coords, elem_vals)
Nnode = numel(x_coords);
Nel   = size(el_2d_no,1);
if numel(elem_vals) ~= Nel
    error('elem_vals length (%d) must match Nel (%d).', numel(elem_vals), Nel);
end
node_vals = zeros(Nnode,1);
weights   = zeros(Nnode,1);
for i = 1:Nel
    nd = el_2d_no(i,:);
    x = x_coords(nd);
    y = y_coords(nd);
    area = 0.5 * abs((x(2)-x(1))*(y(3)-y(1)) - (x(3)-x(1))*(y(2)-y(1)));
    v = elem_vals(i);
    node_vals(nd(1)) = node_vals(nd(1)) + area * v;
    node_vals(nd(2)) = node_vals(nd(2)) + area * v;
    node_vals(nd(3)) = node_vals(nd(3)) + area * v;
    weights(nd) = weights(nd) + area;
end
nz = weights > 0;
node_vals(nz) = node_vals(nz) ./ weights(nz);
end
