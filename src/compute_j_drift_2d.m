function [jx_drift_n, jy_drift_n, jx_drift_p, jy_drift_p] = compute_j_drift_2d(gamma_n, gamma_p, n, p, dphi_dx, dphi_dy, el_2d_no)
% Compute drift current density using precomputed element potential gradients
% Inputs:
% n, p: nodal values
% dphi_dx, dphi_dy: potential gradient for each element (arrays of size Ne)
% el_2d_no: (Ne, nodes_per_elem) element connectivity
% gamma_n, gamma_p: drift coefficients

Ne = size(el_2d_no, 1);
jx_drift_n = zeros(Ne, 1);
jy_drift_n = zeros(Ne, 1);
jx_drift_p = zeros(Ne, 1);
jy_drift_p = zeros(Ne, 1);

for i = 1:Ne
    nodes = el_2d_no(i, :);
    n_elem = n(nodes);
    p_elem = p(nodes);
    nc = mean(n_elem);
    pc = mean(p_elem);

    dphidx = dphi_dx(i);
    dphidy = dphi_dy(i);

    jx_drift_n(i) = -gamma_n * nc * dphidx;
    jy_drift_n(i) = -gamma_n * nc * dphidy;
    jx_drift_p(i) = -gamma_p * pc * dphidx;
    jy_drift_p(i) = -gamma_p * pc * dphidy;
end
end
