% checkneg.m — Inspect nodes where carrier density n_t is negative (or below a tolerance)
%
% Assumptions (variables exist in the workspace):
%   - n_t       : normalized electron density at nodes (vector)
%   - x_coords  : x coordinates (normalized by Lo) at nodes (vector)
%   - y_coords  : y coordinates (normalized by Lo) at nodes (vector)
%   - Lo        : length normalization factor [cm]
%   - n_i       : intrinsic carrier concentration [cm^-3] (optional, used for physical units)
%
% Behavior:
%   - Finds nodes where n_t < tol (default tol = 0)
%   - Prints a small table of those nodes (first 20 rows)
%   - Plots all nodes and highlights the negative ones

tol    = 0;                      % or a small negative tolerance, e.g., -1e-20
idxNeg = find(n_t < tol);        % linear indices of nodes

x_cm = x_coords(idxNeg) * Lo;    % convert normalized length back to cm
y_cm = y_coords(idxNeg) * Lo;

vals = n_t(idxNeg);              % corresponding normalized values (physical value: vals_cm3 = vals * n_i)

T = table(idxNeg, x_cm, y_cm, vals, ...
          'VariableNames', {'nodeIdx','x_cm','y_cm','n_norm'});
disp(T(1:min(20,height(T)), :)); % show only the first 20 rows

figure; scatter(x_coords*Lo, y_coords*Lo, 8, 'k', 'filled'); hold on;
scatter(x_cm, y_cm, 24, 'm', 'filled', 'MarkerEdgeColor','k');
xlabel('x (cm)'); ylabel('y (cm)'); axis equal; box on;
title(sprintf('Nodes with n_t < %g (count=%d)', tol, numel(idxNeg)));