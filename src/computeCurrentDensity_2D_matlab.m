function [jx_drift_n, jy_drift_n, jx_diff_n, jy_diff_n, ...
          jx_drift_p, jy_drift_p, jx_diff_p, jy_diff_p] = ...
          computeCurrentDensity_2D_matlab(id1, id2, id3, xi, eta, ...
          x_coords, y_coords, phi, n, p, mu_n, mu_p, kb, T, q)

    % Node coordinates
    x = [x_coords(id1); x_coords(id2); x_coords(id3)];
    y = [y_coords(id1); y_coords(id2); y_coords(id3)];

    % Nodal values
    phi_elem = [phi(id1); phi(id2); phi(id3)];
    n_elem   = [n(id1);   n(id2);   n(id3)];
    p_elem   = [p(id1);   p(id2);   p(id3)];

    % Element area
    area = 0.5 * abs((x(2)-x(1))*(y(3)-y(1)) - (x(3)-x(1))*(y(2)-y(1)));

    % Shape function derivatives (b -> d/dx coefficients, c -> d/dy coefficients)
    b = [(y(2)-y(3)), (y(3)-y(1)), (y(1)-y(2))] / (2*area);
    c = [(x(3)-x(2)), (x(1)-x(3)), (x(2)-x(1))] / (2*area);

    % Gradients (constant within a triangular element)
    grad_phi = [sum(b.*phi_elem'); sum(c.*phi_elem')];
    grad_n   = [sum(b.*n_elem');   sum(c.*n_elem')];
    grad_p   = [sum(b.*p_elem');   sum(c.*p_elem')];

    % Shape function values
    N1 = 1 - xi - eta;
    N2 = xi;
    N3 = eta;

    % Interpolate n and p at the quadrature point
    n_val = N1*n_elem(1) + N2*n_elem(2) + N3*n_elem(3);
    p_val = N1*p_elem(1) + N2*p_elem(2) + N3*p_elem(3);

    % Diffusion coefficients (Einstein relation)
    Dn = kb*T*mu_n/q;
    Dp = kb*T*mu_p/q;

    % -------------------
    % Drift / diffusion current components
    % -------------------
    % Electrons
    jx_drift_n = -q * mu_n * n_val * grad_phi(1);
    jy_drift_n = -q * mu_n * n_val * grad_phi(2);
    jx_diff_n  =  q * Dn * grad_n(1);
    jy_diff_n  =  q * Dn * grad_n(2);

    % Holes
    jx_drift_p = -q * mu_p * p_val * grad_phi(1);
    jy_drift_p = -q * mu_p * p_val * grad_phi(2);
    jx_diff_p  = -q * Dp * grad_p(1);
    jy_diff_p  = -q * Dp * grad_p(2);
end
