function [err_stiff, err_mass, err_load, err_4x, err_4y] = check_elem_mat( ...
    x_coords, y_coords, el_2d_no, F1, F2, F3, F4x, F4y, varargin)
%VERIFYF123 Verify the correctness of F1, F2, F3
%
% Usage:
%   % Random test
%   [es, em, el] = check_elem_mat(x_coords, y_coords, el_2d_no, F1, F2, F3);
%
%   % Specified test vectors v1, v2
%   [es, em, el] = check_elem_mat(..., v1, v2);
%
% Inputs:
%   x_coords, y_coords      - Node coordinates (Nnode×1 vector)
%   el_2d_no                - Element-node table (Nel×3 matrix)
%   F1, F2                  - Global sparse matrices (Nnode×Nnode)
%   F3                      - Global load vector (Nnode×1)
% Optional inputs:
%   v1, v2                  - Test coefficient vectors (Nnode×1), randomly generated if not provided
%
% Outputs:
%   err_stiff               - Stiffness matrix error: |∫∇φ1·∇φ2 – v1'F1v2|
%   err_mass                - Mass matrix error: |∫φ1φ2   – v1'F2v2|
%   err_load                - Load vector error: |∫φ1     – v1'F3   |
%   err_4x                  - x-derivative integral error: |∫∇_x φ1 * φ2 – v1'F4xv2|
%   err_4y                  - y-derivative integral error: |∫∇_y φ1 * φ2 – v1'F4yv2|

% Number of nodes
Nnode = numel(x_coords);

% Parse optional inputs
if numel(varargin)==2
    v1 = varargin{1};
    v2 = varargin{2};
else
    rng(0,'twister');
    v1 = rand(Nnode,1);
    v2 = rand(Nnode,1);
end

% Additional analytic check using test functions φ1=x-y, φ2=x+2y
fprintf('\nAnalytical validation with test functions φ1=x-y, φ2=x+2y:\n');

% 1) Area & first moments
area = sum(F3);                     % ∫Ω 1 dA
Ix   = x_coords' * F3;              % ∫Ω x dA
Iy   = y_coords' * F3;              % ∫Ω y dA

% 2) Gradient inner product
grad1 = [1; -1];                    % ∇φ1 = [∂x(x-y); ∂y(x-y)] = [1; -1]
grad2 = [1;  2];                    % ∇φ2 = [∂x(x+2y); ∂y(x+2y)] = [1; 2]
I1    = (grad1' * grad2) * area;    % = (1*1 + (-1)*2) * area = -1 * area

% 3) Load integral of φ1
I3    = Ix - Iy;                    % = ∫Ω (x-y) dA

% 4) Mass integral of φ1*φ2
% Expand (x-y)(x+2y) = x² + 2xy - xy - 2y² = x² + xy - 2y²
Ixx   = (x_coords.^2)' * F3;        % ∫Ω x^2 dA
Iyy   = (y_coords.^2)' * F3;        % ∫Ω y^2 dA
Ixy   = (x_coords.*y_coords)' * F3; % ∫Ω x*y dA
I2    = Ixx + Ixy - 2*Iyy;          % ∫Ω (x²+xy-2y²) dA

% 5) integral of ∇_x φ1 * φ2
I4x   = Ix+2*Iy;    % = ∫Ω (x+2y) dA
% 6) integral of ∇_y φ1 * φ2
I4y   = -I4x;       % = ∫Ω (-x-2y) dA

% Specific test vectors for analytical check
v1_test = x_coords - y_coords;      % φ1 = x-y
v2_test = x_coords + 2*y_coords;    % φ2 = x+2y

% Compute discrete approximations
I1_disc = v1_test' * F1 * v2_test;  % Discrete stiffness integral
I2_disc = v1_test' * F2 * v2_test;  % Discrete mass integral
I3_disc = v1_test' * F3;            % Discrete load integral
I4x_disc = v1_test' * F4x * v2_test;  % Discrete x-derivative integral
I4y_disc = v1_test' * F4y * v2_test;  % Discrete y-derivative integral

err_stiff = abs(I1 - I1_disc); % Error in stiffness matrix
err_mass  = abs(I2 - I2_disc); % Error in mass matrix
err_load  = abs(I3 - I3_disc); % Error in load vector
err_4x    = abs(I4x - I4x_disc); % Error in x-derivative integral
err_4y    = abs(I4y - I4y_disc); % Error in y-derivative integral

fprintf('Analytical integrals:\n');
fprintf('  ∫∇φ1·∇φ2 = %.6g\n', I1);
fprintf('  ∫φ1φ2    = %.6g\n', I2);
fprintf('  ∫φ1      = %.6g\n', I3);
fprintf('  ∫∇_x φ1*φ2 = %.6g\n', I4x);
fprintf('  ∫∇_y φ1*φ2 = %.6g\n', I4y);

fprintf('Discrete approximations:\n');
rel_err_stiff = 0; if abs(I1) > 1e-12, rel_err_stiff = err_stiff / abs(I1); end
fprintf('  ∇·∇ : analytical = %.6g, discrete = %.6g, abs error = %.3e, rel error = %.2f%%\n', I1, I1_disc, err_stiff, rel_err_stiff * 100);
rel_err_mass = 0; if abs(I2) > 1e-12, rel_err_mass = err_mass / abs(I2); end
fprintf('  φφ  : analytical = %.6g, discrete = %.6g, abs error = %.3e, rel error = %.2f%%\n', I2, I2_disc, err_mass, rel_err_mass * 100);
rel_err_load = 0; if abs(I3) > 1e-12, rel_err_load = err_load / abs(I3); end
fprintf('  φ   : analytical = %.6g, discrete = %.6g, abs error = %.3e, rel error = %.2f%%\n', I3, I3_disc, err_load, rel_err_load * 100);
rel_err_4x = 0; if abs(I4x) > 1e-12, rel_err_4x = err_4x / abs(I4x); end
fprintf('  ∇_x φ1*φ2 : analytical = %.6g, discrete = %.6g, abs error = %.3e, rel error = %.2f%%\n', I4x, I4x_disc, err_4x, rel_err_4x * 100);
rel_err_4y = 0; if abs(I4y) > 1e-12, rel_err_4y = err_4y / abs(I4y); end
fprintf('  ∇_y φ1*φ2 : analytical = %.6g, discrete = %.6g, abs error = %.3e, rel error = %.2f%%\n', I4y, I4y_disc, err_4y, rel_err_4y * 100);

end
