function [jx_diff_n, jy_diff_n, jx_diff_p, jy_diff_p, dn_dx, dn_dy, dp_dx, dp_dy] = compute_j_diffusion_2d(gamma_n, gamma_p, n, p, el_2d_no, x_coords, y_coords)
% Compute diffusion current density and concentration gradients for 2D triangular elements
% Inputs:
% gamma_n, gamma_p: diffusion coefficients
% n, p: nodal values
% el_2d_no: (Ne, nodes_per_elem) element connectivity
% x_coords, y_coords: nodal coordinates

Ne = size(el_2d_no, 1);
dn_dx = zeros(Ne, 1);
dn_dy = zeros(Ne, 1);
dp_dx = zeros(Ne, 1);
dp_dy = zeros(Ne, 1);
jx_diff_n = zeros(Ne, 1);
jy_diff_n = zeros(Ne, 1);
jx_diff_p = zeros(Ne, 1);
jy_diff_p = zeros(Ne, 1);

for i = 1:Ne
    nodes = el_2d_no(i, :);
    x = x_coords(nodes);
    y = y_coords(nodes);
    n_elem = n(nodes);
    p_elem = p(nodes);

    % Calculate area of triangle
    area = 0.5 * abs((x(2)-x(1))*(y(3)-y(1)) - (x(3)-x(1))*(y(2)-y(1)));

    % Shape function derivatives
    b1 = (y(2)-y(3))/(2*area);
    b2 = (y(3)-y(1))/(2*area);
    b3 = (y(1)-y(2))/(2*area);
    c1 = (x(3)-x(2))/(2*area);
    c2 = (x(1)-x(3))/(2*area);
    c3 = (x(2)-x(1))/(2*area);

    % Concentration gradients (same as potential gradient method)
    dn_dx(i) = b1*n_elem(1) + b2*n_elem(2) + b3*n_elem(3);
    dn_dy(i) = c1*n_elem(1) + c2*n_elem(2) + c3*n_elem(3);
    dp_dx(i) = b1*p_elem(1) + b2*p_elem(2) + b3*p_elem(3);
    dp_dy(i) = c1*p_elem(1) + c2*p_elem(2) + c3*p_elem(3);

    % Diffusion current
    jx_diff_n(i) = gamma_n * dn_dx(i);
    jy_diff_n(i) = gamma_n * dn_dy(i);
    jx_diff_p(i) = -gamma_p * dp_dx(i);
    jy_diff_p(i) = -gamma_p * dp_dy(i);
end
end
