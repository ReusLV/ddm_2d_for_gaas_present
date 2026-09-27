% sweep_steady_current — Voltage sweep script decoupled from the main driver
% It directly calls building blocks (geometry, assembly, Poisson, time stepping,
% post-processing) to reach steady state for each Ubias and computes the
% drift/diffusion/total current through the top electrode.


clearvars -except load_only load_csv_path contact_mode fem include_ohmic_reference include_schottky_reference;
clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);

% ===================== User Options =====================
% If load_only is true, the script skips the full computation and only loads
%  1) Set load_only to true;
%  2) Optionally: set load_csv_path to point to a previously saved result CSV; leave empty to default to ./results/iv_sweep_drift_diff.csv.
if ~exist('load_only','var'); load_only = 1; end   % true: only load and plot; false: calculate normally
if ~exist('load_csv_path','var') || isempty(load_csv_path)
    load_csv_path = fullfile(projectRoot, 'results', ...
        'iv_sweep_drift_diff_schottky.csv');
end
% ========================================================

% Voltage sweep list (V)
% Ubias_list = linspace(-0.2, 1, 8);
Ubias_list = [-0.2, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.8, 1];
% Numerical parameters
dt    = 1e-13;   % s
Nt    = 3000;    % max steps
Relax = 5e-1;    % Gummel relaxation
contact_mode = 'schottky';
fem = 0;
% if ~exist('fem','var'); fem = true; end % Use FEM-style current computation (true) or FD-style (false)

% Contact type switch: choose 'ohmic' or 'schottky'
% if ~exist('contact_mode','var'); contact_mode = 'ohmic'; end
schottky = strcmpi(contact_mode,'schottky');  % false -> Ohmic; true -> Schottky
fprintf('Contact mode: %s\n', contact_mode);
if schottky
    include_ohmic_reference=0;
    include_schottky_reference=1;
else
    include_ohmic_reference=1;
    include_schottky_reference=0;
end
% Optional: Embedded Ohmic reference I–V data (provided values)
if ~exist('include_ohmic_reference','var'); include_ohmic_reference = strcmpi(contact_mode,'ohmic'); end
ohmic_ref.Ubias_V = [0.0, 0.3, 0.5, 0.8, 1.0];
ohmic_ref.I_A     = [0.0, 0.012839, 0.021401, 0.034058, 0.042817];

% Optional: Embedded Schottky reference I–V data (provided values)
if ~exist('include_schottky_reference','var'); include_schottky_reference = strcmpi(contact_mode,'schottky'); end
schottky_ref.Ubias_V = [1.0, 0.8, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0,-0.2];
schottky_ref.I_A     = [2.6096e-02, 1.7937e-02, 6.2830e-03, 2.8940e-03, 5.3195e-04, 1.7551e-05, 3.4545e-07, 4.2206e-16,-6.99e-06];


if load_only
    outDirDefault = fullfile(projectRoot, 'results');
    if isempty(load_csv_path)
        load_csv_path = fullfile(outDirDefault, 'iv_sweep_drift_diff.csv');
    end
    if ~isfile(load_csv_path)
        error('load_only=true but file not found: %s', load_csv_path);
    end
    fprintf('\nLoad-only mode: saved output -> %s\n', load_csv_path);
    results = readtable(load_csv_path);

    figure; plot(results.Ubias_V, results.I_total_A, 'o-','LineWidth',1.8); hold on;
    plot(results.Ubias_V, results.I_drift_A, 's--','LineWidth',1.2);
    plot(results.Ubias_V, results.I_diff_A,  'd--','LineWidth',1.2);
    legendEntries = {'Total (drift+diff)','Drift','Diffusion'};
    if schottky && any(ismember(results.Properties.VariableNames, 'I_schottky_A'))
        plot(results.Ubias_V, results.I_schottky_A, 'c-.', 'LineWidth', 1.5);
        if any(ismember(results.Properties.VariableNames, 'I_schottky_A_flip'))
            plot(results.Ubias_V, results.I_schottky_A_flip, 'r:', 'LineWidth', 1.5);
            legendEntries{end+1} = 'Schottky (BC emission)';
            legendEntries{end+1} = 'Schottky (BC emission, flipped)';
        else
            legendEntries{end+1} = 'Schottky (BC emission)';
        end
    end
    if include_ohmic_reference
        plot(ohmic_ref.Ubias_V, ohmic_ref.I_A, 'k-.', 'LineWidth', 1.5);
        legendEntries{end+1} = 'COMSOL reference';
    end
    if include_schottky_reference
        plot(schottky_ref.Ubias_V, schottky_ref.I_A, 'm:', 'LineWidth', 1.5);
        legendEntries{end+1} = 'COMSOL reference';
    end
    grid on; xlabel('Ubias (V)'); ylabel('Current (A)');
    legend(legendEntries, 'Location','best');
    title('');
else

% Result containers
nV = numel(Ubias_list);
I_total_A = nan(nV,1);  % total top-electrode current (A) = drift + diffusion
I_drift_A = nan(nV,1);
I_diff_A  = nan(nV,1);
conv_step = nan(nV,1);
I_sch_A   = nan(nV,1);   % Schottky emission current from BC model (A)
J_sch_Acm2 = nan(nV,1);  % Schottky current density (A/cm^2)
% Vertical cut currents at x=0.8*L_n over y in [0, 2.1 um]
I_vline_total_A = nan(nV,1);
I_vline_drift_A = nan(nV,1);
I_vline_diff_A  = nan(nV,1);

% Load constants, materials, normalization parameters
global_constants;              % kB, e, ...
Semiconductor_parameters;      % T, mu_n, mu_p, n_i, Nd, Nd_n, bi, bi_n, ...
Normalization_Parameters;      % Vt, Lo, Jo, Mo, ...
% Optional: Schottky constants (for S1n/S0n/S1p/S0p). We default to ohmic-only.
try
    schottky_constants;        % vsn, vsp, n_sc, p_sc, phiB, chi0, qn, qp
catch
    % Safe defaults (disable contact injection terms)
    vsn = 0; vsp = 0; n_sc = 0; p_sc = 0; qn = 1; qp = -1;
end

% Build geometry and mesh
geometry_mesh_new;             % defines x_coords, y_coords, el_2d_no, H1, H2, L_n, L_nn, e_start, e_end, Nel, Nnode
boundary_nodes;                % st_no boundary flag

% Initial carriers
define_initial_conditions;     % n0, p0

% Assemble Poisson and contact boundary matrices
matrix_assembly_Poisson;       % F1, F2, S1n/S0n/S1p/S0p

% Precompute voltage-independent parameters
gamma_n = mu_n / Mo;           % normalized mobilities
gamma_p = mu_p / Mo;
tol = 1e-8;
device_thickness = 1e-4;       % cm (consistent with main script)

for k = 1:nV
    Ubias = Ubias_list(k);
    fprintf('\n==== Ubias = %.3f V ====\n' , Ubias);

    % Dirichlet potentials at the three electrodes (dimensionless)
    % Ohmic mode (default): DBC1 = Ubias/Vt + offset/Vt + bi/Vt
    % Schottky mode: include barrier and affinity shifts (phiB, chi0)
    offset = -4.03;  % from main script
    Veq_adj = 0; gap = 0; %#ok<NASGU> % optional corrections, default to 0
    if schottky
        % Guard missing constants
        if ~exist('phiB','var') || ~exist('chi0','var')
            warning('schottky selected but phiB/chi0 not found. Call schottky_constants or define them. Using defaults from schottky_constants try-block.');
        end
        % Use k_B (eV/K from schottky_constants) and Vt (V)
        if exist('k_B','var')
            kB_eV = k_B; % eV/K
        else
            % Fallback: convert SI kB [J/K] to eV/K
            kB_eV = kB / q; %#ok<NODEF> q from global_constants
        end
        DBC1 = Ubias / Vt - phiB / (kB_eV * T) - chi0 / (kB_eV * T) - Veq_adj / Vt + bi / Vt + gap / Vt;
        DBC2 = offset / Vt + bi / Vt + gap / Vt;
        DBC3 = offset / Vt + bi_n / Vt + gap / Vt;
    else
        DBC1 = Ubias / Vt + offset / Vt + bi / Vt;
        DBC2 = offset / Vt + bi / Vt;
        DBC3 = offset / Vt + bi_n / Vt;
    end

    % Initial values
    n_1 = n0; p_1 = p0;
    n_last = n_1; p_last = p_1;

    % Time stepping with Gummel relaxation to steady state
    for istep = 1:Nt
        % 1) Poisson solve
        phi = solve_Poisson_problem(F1, F2, p_1, n_1, N_a, N_d, DBC1, DBC2, DBC3, ...
                                    x_coords, y_coords, st_no, H1, H2, L_n, L_nn, e_start, e_end);
        electric_field; % yields dphi_dx, dphi_dy
        G1 = Compute_Matrix_G(dphi_dx, dphi_dy, x_coords, y_coords, el_2d_no);

        % 2) One drift-diffusion step
        % DBC order (consistent with the main script): [p_n, n_n, p_nn, n_nn]
    [n_2, p_2] = Time_Step_Drift_Diffusion(n_1, p_1, F1, F2, G1, S1n, S0n, S1p, S0p, ...
                gamma_n, gamma_p, dt, [p_n, n_n, p_nn, n_nn], schottky, ...
                            st_no, x_coords, y_coords, el_2d_no, L_n, L_nn, H1, H2, e_start, e_end, tol, ...
                            qn, vsn, vsp, n_sc, p_sc);

        % 3) Gummel relaxation
        n_t = n_1 + Relax * (n_2 - n_1);
        p_t = p_1 + Relax * (p_2 - p_1);

        % 4) Inner convergence check (single update per step; wrap a while if needed)
        n_1 = n_t; p_1 = p_t;

        % Steady-state detection: change between consecutive time steps
        if istep > 1
            dn_step = norm(n_1 - n_last) / max(1e-30, norm(n_1));
            if dn_step < 1e-5
                fprintf(' -> steady at step %d\n', istep);
                conv_step(k) = istep;
                break;
            end
        end
        n_last = n_1; p_last = p_1;
    end

    % At final state, compute drift and diffusion current densities (element-based, dimensionless)
    if ~fem
    [jx_drift_n, jy_drift_n, jx_drift_p, jy_drift_p] = compute_j_drift_2d(gamma_n, gamma_p, n_t, p_t, dphi_dx, dphi_dy, el_2d_no);
    [jx_diff_n,  jy_diff_n,  jx_diff_p,  jy_diff_p,  ~, ~, ~, ~] = compute_j_diffusion_2d(gamma_n, gamma_p, n_t, p_t, el_2d_no, x_coords, y_coords);
    jx_drift_tot = jx_drift_n + jx_drift_p;
    jy_drift_tot = jy_drift_n + jy_drift_p;
    jx_diff_tot  = jx_diff_n  + jx_diff_p;
    jy_diff_tot  = jy_diff_n  + jy_diff_p;

    % Integrate normal current over the top electrode window (dimensionless)
    I_drift_norm = compute_contact_current(el_2d_no, x_coords, y_coords, jx_drift_tot, jy_drift_tot, H1, H2, e_start, e_end, L_n, tol);
    I_diff_norm  = compute_contact_current(el_2d_no, x_coords, y_coords, jx_diff_tot,  jy_diff_tot,  H1, H2, e_start, e_end, L_n, tol);
    I_drift_A(k) = I_drift_norm * Jo * Lo * device_thickness;
    I_diff_A(k)  = I_diff_norm  * Jo * Lo * device_thickness;
    I_total_A(k) = I_drift_A(k) + I_diff_A(k);

    % Vertical line current at x = 0.8*L_n, y in [0, 2.1 um]
    x0_norm   = 0.8 * L_n;                 % normalized x position
    y_min_norm = 0;                        % bottom
    y_max_norm_target = 2.1e-4 / Lo;       % 2.1 um = 2.1e-4 cm, normalize by Lo
    y_max_norm = min(H1 + H2, y_max_norm_target); % clip within domain just in case
    if y_max_norm <= y_min_norm
        I_vline_total_A(k) = NaN; I_vline_drift_A(k) = NaN; I_vline_diff_A(k) = NaN;
    else
        I_vline_drift_norm = compute_vertical_line_current(el_2d_no, x_coords, y_coords, jx_drift_tot, x0_norm, y_min_norm, y_max_norm, tol);
        I_vline_diff_norm  = compute_vertical_line_current(el_2d_no, x_coords, y_coords, jx_diff_tot,  x0_norm, y_min_norm, y_max_norm, tol);
        I_vline_total_norm = I_vline_drift_norm + I_vline_diff_norm;
        I_vline_drift_A(k) = I_vline_drift_norm * Jo * Lo * device_thickness;
        I_vline_diff_A(k)  = I_vline_diff_norm  * Jo * Lo * device_thickness;
        I_vline_total_A(k) = I_vline_total_norm * Jo * Lo * device_thickness;
    end

    else
        % Compute current components directly using FEM-style boundary integration
    [I_total_norm, I_drift_n_norm, I_diff_n_norm, I_drift_p_norm, I_diff_p_norm] = ...
        computeCurrent_2D_matlab(el_2d_no, x_coords*Lo, y_coords*Lo, ...
                                phi*Vt, n_t*n_i, p_t*n_i, ...
                                mu_n, mu_p, kB, T, q, ...
                                H1*Lo, H2*Lo, e_start*Lo, e_end*Lo, tol);

    % Drift current = electron drift + hole drift
    I_drift_norm = I_drift_n_norm + I_drift_p_norm;

    % Diffusion current = electron diffusion + hole diffusion
    I_diff_norm  = I_diff_n_norm  + I_diff_p_norm;

    % Convert to Amperes
    I_drift_A(k) = I_drift_norm * device_thickness;
    I_diff_A(k)  = I_diff_norm  * device_thickness;
    I_total_A(k) = I_total_norm * device_thickness;
    end

    % Schottky contact emission current (from boundary condition model)
    if schottky
        [I_sch_phys, J_sch_phys_density] = compute_schottky_contact_current( ...
            n_t, p_t, x_coords, y_coords, el_2d_no, H1, H2, e_start, e_end, tol, ...
            vsn, vsp, n_sc, p_sc, Lo, Jo, device_thickness);
        I_sch_A(k)    = I_sch_phys;
        J_sch_Acm2(k) = J_sch_phys_density;
    end
end

% Save and plot
I_sch_flip = -I_sch_A; % Flip sign to match the drift-diffusion current direction convention
results = table(Ubias_list(:), I_total_A(:), I_drift_A(:), I_diff_A(:), conv_step(:), ...
    I_sch_A(:), I_sch_flip(:), J_sch_Acm2(:), ...
    I_vline_total_A(:), I_vline_drift_A(:), I_vline_diff_A(:), ...
    'VariableNames', {'Ubias_V','I_total_A','I_drift_A','I_diff_A','steady_step_idx','I_schottky_A','I_schottky_A_flip','J_schottky_Acm2','I_vline_total_A','I_vline_drift_A','I_vline_diff_A'});

outDir = fullfile(projectRoot, 'results'); if ~exist(outDir,'dir'); mkdir(outDir); end
csvPath = fullfile(outDir, 'iv_sweep_drift_diff.csv');
writetable(results, csvPath);
fprintf('\nSaved results to: %s\n', csvPath);

figure; plot(results.Ubias_V, results.I_total_A, 'o-','LineWidth',1.8); hold on;
plot(results.Ubias_V, results.I_drift_A, 's--','LineWidth',1.2);
plot(results.Ubias_V, results.I_diff_A,  'd--','LineWidth',1.2);
plot(results.Ubias_V, results.I_vline_total_A, 'c-.', 'LineWidth', 1.5);
plot(results.Ubias_V, results.I_vline_drift_A, 'm--o', 'LineWidth', 1.2);
plot(results.Ubias_V, results.I_vline_diff_A,  'r--d', 'LineWidth', 1.2);

% Overlay Ohmic reference curve if requested
legendEntries = {'Total (drift+diff)','Drift','Diffusion', 'Vline total', 'Vline drift', 'Vline diffusion'};
if schottky
    plot(results.Ubias_V, results.I_schottky_A, 'c-.', 'LineWidth', 1.5);
    plot(results.Ubias_V, results.I_schottky_A_flip, 'r:', 'LineWidth', 1.5);
    legendEntries{end+1} = 'Schottky (BC emission)';
    legendEntries{end+1} = 'Schottky (BC emission, flipped)';
end
if include_ohmic_reference
    plot(ohmic_ref.Ubias_V, ohmic_ref.I_A, 'k-.', 'LineWidth', 1.5);
    legendEntries{end+1} = 'Ohmic reference';
    % Save the ohmic reference as CSV for reproducibility
    refCsvPath = fullfile(outDir, 'ohmic_reference_iv.csv');
    writetable(table(ohmic_ref.Ubias_V(:), ohmic_ref.I_A(:), 'VariableNames', {'Ubias_V','I_ref_A'}), refCsvPath);
    fprintf('Saved ohmic reference to: %s\n', refCsvPath);
end
if include_schottky_reference
    plot(schottky_ref.Ubias_V, schottky_ref.I_A, 'm:', 'LineWidth', 1.5);
    legendEntries{end+1} = 'Schottky reference';
    % Save the schottky reference as CSV for reproducibility
    refCsvPath2 = fullfile(outDir, 'schottky_reference_iv.csv');
    writetable(table(schottky_ref.Ubias_V(:), schottky_ref.I_A(:), 'VariableNames', {'Ubias_V','I_ref_A'}), refCsvPath2);
    fprintf('Saved schottky reference to: %s\n', refCsvPath2);
end
grid on; xlabel('Ubias (V)'); ylabel('Current (A)');
legend(legendEntries, 'Location','best');
title('Top Electrode Current vs Ubias (Drift-Diffusion)');

% Plot vertical cut current at x=0.8*L_n, y in [0, 2.1 um]
figure; hold on;
plot(results.Ubias_V, results.I_vline_total_A, 'm-o', 'LineWidth', 1.8, 'DisplayName','Vline total');
plot(results.Ubias_V, results.I_vline_drift_A, 'b--s', 'LineWidth', 1.2, 'DisplayName','Vline drift');
plot(results.Ubias_V, results.I_vline_diff_A,  'r--d', 'LineWidth', 1.2, 'DisplayName','Vline diffusion');
plot(ohmic_ref.Ubias_V, ohmic_ref.I_A, 'k-.', 'LineWidth', 1.5, 'DisplayName','COMSOL reference');
grid on; xlabel('Ubias (V)'); ylabel('Current (A)');
legend('Location','best');
title('Vertical cut current at x = 0.8 L_n, y \in [0, 2.1 \mum]');
end
