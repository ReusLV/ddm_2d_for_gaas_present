function [I_phys, J_phys_density, j_norm, j_norm_n, j_norm_p, J_phys_density_n, J_phys_density_p] = compute_schottky_contact_current(n, p, x_coords, y_coords, el_2d_no, H1, H2, e_start, e_end, tol, vsn, vsp, n_sc, p_sc, Lo, Jo, device_thickness)
% compute_schottky_contact_current
%   Implements Schottky contact emission current using formula
%       J = - q v (n - n0)
%       and for holes (with opposite sign convention at boundary):
%       J_p(inward) = + q v_p (p - p0)
%   In the code base, variables are normalized:
%       n, n_sc are normalized by n_i
%       p, p_sc are normalized by n_i
%       v (vsn) is normalized by (D0 / L0)
%       The current density normalization constant is Jo = q * n_i * D0 / L0
%   Therefore the dimensionless current density is:
%       j_norm_n = -vsn * (n - n_sc)    % electrons, inward-positive
%       j_norm_p = +vsp * (p - p_sc)    % holes, inward-positive
%       j_norm   = j_norm_n + j_norm_p
%   Converting back to physical current density (A/cm^2): J_phys = j_norm * Jo
%   Total current (A) = J_phys * ContactArea, where ContactArea = (electrode_length) * device_thickness
%
% Inputs:
%   n                - normalized electron concentration (Nnode x 1)
%   p                - normalized hole concentration (Nnode x 1)
%   x_coords,y_coords- nodal coordinates (normalized by L0)
%   el_2d_no         - element connectivity (Ne x nnpe)
%   H1,H2            - vertical region heights (normalized)
%   e_start,e_end    - x-range of Schottky electrode (normalized)
%   tol              - tolerance for identifying boundary nodes
%   vsn              - normalized surface recombination / emission velocity
%   vsp              - normalized hole surface recombination / emission velocity
%   n_sc             - normalized equilibrium electron concentration at contact
%   p_sc             - normalized equilibrium hole concentration at contact
%   Jo               - current density normalization constant (A/cm^2)
%   device_thickness - assumed thickness in z direction (cm)
%
% Outputs:
%   I_phys             - total contact current (A)
%   J_phys_density     - average physical current density over the electrode (A/cm^2)
%   j_norm             - average dimensionless current density over the electrode
%   j_norm_n (optional)- electron component (dimensionless)
%   j_norm_p (optional)- hole component (dimensionless)
%   J_phys_density_n (optional) - electron component average (A/cm^2)
%   J_phys_density_p (optional) - hole component average (A/cm^2)

    % Traverse boundary edges on the top electrode and perform line integration
    Ne = size(el_2d_no,1);
    edges_local = [1 2; 2 3; 3 1];

    j_int_tot = 0.0;    % integral of dimensionless total J over normalized length
    j_int_n   = 0.0;    % electron component integral (dimensionless)
    j_int_p   = 0.0;    % hole component integral (dimensionless)
    L_norm_sum = 0.0;   % total normalized electrode length accumulated

    y_top = (H1 + H2);
    for e = 1:Ne
        nodes = el_2d_no(e,:);
        for k = 1:size(edges_local,1)
            i1 = nodes(edges_local(k,1));
            i2 = nodes(edges_local(k,2));
            x1 = x_coords(i1); y1 = y_coords(i1);
            x2 = x_coords(i2); y2 = y_coords(i2);

            % Check if this edge lies on the top electrode window
            if abs(y1 - y_top) < tol && abs(y2 - y_top) < tol && ...
               x1 >= (e_start - tol) && x1 <= (e_end + tol) && ...
               x2 >= (e_start - tol) && x2 <= (e_end + tol)

                % Normalized edge length
                dx = x2 - x1; dy = y2 - y1;
                L_norm = sqrt(dx*dx + dy*dy);
                if L_norm == 0
                    continue;
                end

                % Dimensionless current densities at the two nodes
                jn1 = -vsn * (n(i1) - n_sc);
                jn2 = -vsn * (n(i2) - n_sc);
                jp1 =  vsp * (p(i1) - p_sc);
                jp2 =  vsp * (p(i2) - p_sc);
                j1 = jn1 + jp1;
                j2 = jn2 + jp2;

                % Exact 1D linear element integration: ∫_{-1}^1 [N1*j1 + N2*j2] dxi = j1 + j2
                % Physical integral adds Jacobian = L_phys/2; with normalized length, Jacobian = (L_norm*Lo)/2
                j_int_tot = j_int_tot + (L_norm/2) * (j1 + j2);
                j_int_n   = j_int_n   + (L_norm/2) * (jn1 + jn2);
                j_int_p   = j_int_p   + (L_norm/2) * (jp1 + jp2);
                L_norm_sum = L_norm_sum + L_norm;
            end
        end
    end

    if L_norm_sum == 0
        % No electrode edge found
        I_phys = 0; J_phys_density = 0; j_norm = 0; 
        if nargout > 3
            j_norm_n = 0; j_norm_p = 0; J_phys_density_n = 0; J_phys_density_p = 0;
        end
        return;
    end

    % Convert integrated dimensionless current density to physical current (A)
    % I = (Jo) * (Lo) * (device_thickness) * j_int_tot
    I_phys = Jo * Lo * device_thickness * j_int_tot;

    % Average current densities over the electrode length (A/cm^2)
    electrode_length_norm = L_norm_sum;
    electrode_length_phys = electrode_length_norm * Lo;
    J_phys_density   = I_phys / (electrode_length_phys * device_thickness);
    J_phys_density_n = Jo * (j_int_n / electrode_length_norm);
    J_phys_density_p = Jo * (j_int_p / electrode_length_norm);

    % Corresponding average dimensionless densities
    j_norm   = j_int_tot / electrode_length_norm; 
    j_norm_n = j_int_n   / electrode_length_norm;
    j_norm_p = j_int_p   / electrode_length_norm;

    fprintf('electrode_length (normalized) = %.4e\n', electrode_length_norm);
    fprintf('electrode_length (cm) = %.4e\n', electrode_length_phys);
    fprintf('device_thickness (cm) = %.4e\n', device_thickness);
end
