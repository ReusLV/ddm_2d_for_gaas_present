% 2-D transient drift-diffusion analysis of a layered GaAs n+/n device.

clear;clc;close all;

% Semiconductor Data
% ******************************************************
Px1=100;Px2=600;Py1=100;Py2=320;    % Size of figures
plot_mesh=1;
plot_initial_conditions=0;
plot_final_solution=1;
plotcutline=0;
plot_initial_potential=0;
plot_initial_E_field=0;
plot_intermediate_potential=0;
plot_intermediate_E_field=0;
plot_intermediate_n=0;
plot_intermediate_p=0;
read_initial_solution=0;
save_figs=0;
comp=1;
schottky=1;
global_constants;
Semiconductor_parameters;
% End of Semiconductor Data
% ******************************************************

Normalization_Parameters;
schottky_constants;

if 1
fprintf('Vt=%14.6e (V)\n',Vt);
fprintf('Lo=%14.6e (cm)\n',Lo);
fprintf('Dn=%14.6e (cm^2/s)\n',Dn);
fprintf('Dp=%14.6e (cm^2/s)\n',Dp);
fprintf('Do=%14.6e (cm^2/s)\n',Do);
fprintf('to=%14.6e (s)\n',to);
fprintf('Mo=%14.6e (cm^2/(Vs))\n',Mo);
fprintf('Go=%14.6e (cm^-3/s)\n',Go);
fprintf('Jo=%14.6e (A/cm^2)\n',Jo);
end

% Define the 1-D semiconductor geometry and mesh
% The units of length are (cm)
% geometry_mesh;
geometry_mesh_new;

analyze_mesh(el_2d_no, x_coords, y_coords); % Call the mesh analysis script

if plot_mesh
    geometry_plot;
    mesh_plot_new;
    axis on;
    xlabel('Position (cm)');
end

boundary_nodes;

% Define Intial Conditions, just carriers concentrations
define_initial_conditions;

% --- Sanity Check Probe ---
fprintf('\n--- Initial Condition Sanity Check ---\n');
fprintf('n0 max: %e, min: %e, mean: %e\n', max(n0), min(n0), mean(n0));
fprintf('p0 max: %e, min: %e, mean: %e\n', max(p0), min(p0), mean(p0));
net_charge = p0 - n0 + N_d - N_a;
fprintf('Initial Net Charge max: %e, min: %e, mean: %e\n', max(net_charge), min(net_charge), mean(net_charge));
fprintf('--------------------------------------\n\n');
% --- End Sanity Check Probe ---

if read_initial_solution
   load td_solution_bias_0p5V.mat;
   p0=pt(:,end);
   n0=nt(:,end);
end

if plot_initial_conditions % initial carriers concentrations
plot_electron_concentration(n0, 0, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no);
plot_hole_concentration(p0, 0, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no);
end

% Compute Intial Potential Distribution
matrix_assembly_Poisson;
% check_elem_mat(x_coords, y_coords, el_2d_no, F1, F2, F3, F4x, F4y);

% Define 2D Dirichlet Boundary Conditions
DBC1 = -1;    % Dirichlet BC for the n - top boundary
DBC2 = 0;    % Dirichlet BC for the n - right boundary
DBC3 = 0;    % Dirichlet BC for the n+ - top  boundary

% Apply boundary conditions to the 2D geometry
phi = solve_Poisson_problem(F1,F2,p0,n0,N_a,N_d,DBC1,DBC2,DBC3,x_coords,y_coords,st_no,H1,H2,L_n,L_nn,e_start,e_end);
% [dphi_dx, dphi_dy] = compute_dphi(phi, el_2d_no, x_coords, y_coords); % Output: d_phi/dx and dphi_dy
electric_field; % Compute electric field and energy, also store dphi_dx and dphi_dy  

if plot_initial_potential
plot_potential(phi, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no);
end

if plot_initial_E_field
plot_electric_field(Eabs, Nnode, Nel, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no)
end

% Display Poisson solution statistics
fprintf('Poisson Solution statistics: min=%.6e, max=%.6e, mean=%.6e\n', min(phi), max(phi), mean(phi));
% fprintf('Computed element gradients: dphi_dx range [%.6e, %.6e], dphi_dy range [%.6e, %.6e]\n', min(dphi_dx), max(dphi_dx), min(dphi_dy), max(dphi_dy));
fprintf('Computed nodal electric field: Ex range [%.6e, %.6e], Ey range [%.6e, %.6e]\n', min(Ex), max(Ex), min(Ey), max(Ey));

% Compute Matrix G
G1=Compute_Matrix_G(dphi_dx,dphi_dy,x_coords,y_coords,el_2d_no);
% check_elem_mat(x_coords, y_coords, el_2d_no, F1, F2, F3);

% Time Integration of Drift-Diffusion + Poisson Equations
gamma_n=mu_n/Mo;
gamma_p=mu_p/Mo;
Tau_n=tau_n/to;
Tau_p=tau_p/to;
dt=1e-13;
Nt=3000;
Relax=5e-1;      % Relaxation parameter for Gummel's method, further reduced for stability
n_1=n0;p_1=p0;

Ubias=0.;
phim = phiB+chi0; % Metal work function
offset=-4.03;
gap = -0.711;
% if schottky
%     offset=chi0-phim+Eg/2+k_B*T/2*log(Nc/Nv);
% else
%     offset=k_B*T*log(Nd/n_i); 
% end
% Unit guard: compute DBC1 using volts only (avoid eV/V mix)
Vt_V = Vt;         % [V]
Vt_eV = k_B*T;     % [eV] (for info)
phiB_V = phiB;     % treat eV barrier as equivalent volts for potential drop
chi0_V = chi0;     % same for electron affinity

% Choose COMSOL form or condensed form

if schottky
    % DBC1 = (Ubias - (phiB_V + chi0_V + Veq_adj)) / Vt_V; 
    DBC1 = Ubias/Vt - phiB/k_B/T - chi0/k_B/T - Veq_adj/Vt + bi/Vt + gap/Vt; % Convert to normalized units
    DBC2 = offset/Vt + bi/Vt + gap/Vt; DBC3 = offset/Vt + bi_n/Vt + gap/Vt;
else
    DBC1 = Ubias / Vt + offset / Vt + bi / Vt + gap/Vt; 
    DBC2=offset/Vt + bi/Vt + gap/Vt; DBC3=offset/Vt + bi_n/Vt + gap/Vt;
end

fprintf('Units check: Vt=%.4e V (%.4e eV), phiB=%.3f eV(~%.3f V), chi0=%.3f eV(~%.3f V)\n', Vt_V, Vt_eV, phiB, phiB_V, chi0, chi0_V);

inc=1; Ns=floor(Nt/inc); 

% Solution storing parameter
nt=zeros(Nnode,Ns);pt=zeros(Nnode,Ns);t=zeros(Ns,1);phit=zeros(Nnode,Ns);

jx_nt=zeros(Nel,Ns);jx_pt=zeros(Nel,Ns);
jx_diff_nt=zeros(Nel,Ns);jx_diff_pt=zeros(Nel,Ns);
jx_drift_nt=zeros(Nel,Ns);jx_drift_pt=zeros(Nel,Ns);

jy_nt=zeros(Nel,Ns);jy_pt=zeros(Nel,Ns);
jy_diff_nt=zeros(Nel,Ns);jy_diff_pt=zeros(Nel,Ns);
jy_drift_nt=zeros(Nel,Ns);jy_drift_pt=zeros(Nel,Ns);
rho_t=zeros(Nnode,Ns); % Normalized total charge concentration
I_norm = zeros(length(t),1);
I_top = zeros(length(t),1);
I_sch = zeros(length(t),1); % Schottky emission current using -q v (n - n0)
J_sch_density = zeros(length(t),1); % Corresponding current density (A/cm^2)
count1=0;count2=0;

% In sweep mode, force all plots off to speed up
if exist('SWEEP_MODE','var') && SWEEP_MODE
    plot_mesh=0; plot_initial_conditions=0; plot_final_solution=0; plotcutline=0;
    plot_initial_potential=0; plot_initial_E_field=0;
    plot_intermediate_potential=0; plot_intermediate_E_field=0;
    plot_intermediate_n=0; plot_intermediate_p=0; save_figs=0; comp=0;
end

% Loop Over Time
n_last = n_1;
p_last = p_1;
for istep=1:Nt
    
    if 1 % Adaptivity of the step
    if istep>1500
        dt=1e-12;
    end
    % (Removed unreachable dt adaptivity branches previously guarded by && 0)
    end
    
    % waitbar(istep/Nt);
    
    count1=count1+1;
    
    conv=0;
    % n_t is the {n}^i or {n}^i+1 in the instruction pdf
    n_t=n_1;p_t=p_1;
    iter=1;
    while conv==0
        phi = solve_Poisson_problem(F1,F2,p_t,n_t,N_a,N_d,DBC1,DBC2,DBC3,x_coords,y_coords,st_no,H1,H2,L_n,L_nn,e_start,e_end);
        electric_field; % Output: dphi_dx(Nel,1), dphi_dy(Nel,1) - element-based gradients        

        G1=Compute_Matrix_G(dphi_dx,dphi_dy,x_coords,y_coords,el_2d_no);

        % DBC struct: [p in n-region top, n in n-region top, p in n+-region top, n in n+-region top]
        [n_2,p_2]=Time_Step_Drift_Diffusion(n_1,p_1,F1,F2,G1,S1n,S0n,S1p,S0p,gamma_n,gamma_p,dt,[p_n,n_n,p_nn,n_nn],schottky,st_no,x_coords,y_coords,el_2d_no,L_n,L_nn,H1,H2,e_start,e_end,tol,qn,vsn,vsp,n_sc,p_sc);
        % [n_2,p_2]=Time_Step_Drift_Diffusion(n_1,p_1,F1,F2,G1,S1n,S0n,S1p,S0p,gamma_n,gamma_p,dt,[p_n,n_n,p_nn,n_nn],schottky,st_no,x_coords,y_coords,el_2d_no,L_n,L_nn,H1,H2,e_start,e_end,tol);
        phi2=solve_Poisson_problem(F1,F2,p_2,n_2,N_a,N_d,DBC1,DBC2,DBC3,x_coords,y_coords,st_no,H1,H2,L_n,L_nn,e_start,e_end); % Output: phi=Phi/Vt
        dn=norm(n_2-n_t)/norm(n_2);
        dp=norm(p_2-p_t)/norm(p_2);
        fprintf('Iteration %d: dn=%14.6e dp=%14.6e\n',iter,dn,dp);  

        n_t=n_t+Relax*(n_2-n_t); % 0.5*n_2+0.5*n_t;
        p_t=p_t+Relax*(p_2-p_t);      
        
        % Close all figures if not converged yet
        if max(dn,dp)>=0.0001
            close all;
        end
        
        if max(dn,dp)<0.0001
            conv=1; 
        end
        iter=iter+1;
    end
    
    n_1=n_2;p_1=p_2;
    % Check convergence between time steps (steady-state detection)
    if istep > 1
        dn_step = norm(n_1 - n_last) / norm(n_1);
        fprintf('Time step %d: dn_step=%e\n', istep, dn_step);
        % If both carrier concentrations change less than the threshold, stop simulation early
        if dn_step < 1e-5 % Threshold can be adjusted
            fprintf('Time step convergence reached at step %d\n', istep);
            % Un-normalize fields, potentials, and coordinates to physical units before plotting
            % phi is normalized by Vt -> Phi_phys = phi * Vt
            % If coordinates are normalized by Lo, then |grad(phi)| is w.r.t x' = x/Lo, so E_phys = (Vt/Lo)*|grad(phi)| (V/cm)
            phi_phys = phi * Vt;           % [V]
            Eabs_phys = (Vt/Lo) * Eabs;    % [V/cm]
            % Carrier concentrations are normalized by n_i
            n_phys = n_t * n_i;            % [cm^-3]
            p_phys = p_t * n_i;            % [cm^-3]

            % Coordinates to physical units (cm)
            x_coords_phys = x_coords * Lo; % [cm]
            y_coords_phys = y_coords * Lo; % [cm]
            if plot_final_solution
                plot_electric_field_phys(Eabs_phys, Nnode, Nel, Px1, Py1, Px2, Py2, x_coords_phys, y_coords_phys, el_2d_no);
                plot_potential_phys(phi_phys, Px1, Py1, Px2, Py2, x_coords_phys, y_coords_phys, el_2d_no);
                plot_electron_concentration_phys(n_phys, iter, Px1, Py1, Px2, Py2, x_coords_phys, y_coords_phys, el_2d_no, 'CLim',[1e16 1e18]);
                plot_hole_concentration_phys(p_phys, iter, Px1, Py1, Px2, Py2, x_coords_phys, y_coords_phys, el_2d_no);
            end
            % Plot in physical units
            break;
        end
    end
    n_last = n_1;
    p_last = p_1;

    % Store the solution
    if inc==count1 % Store Solution
        count2=count2+1;
        t(count2)=istep*dt;
        nt(:,count2)=n_2;
        pt(:,count2)=p_2;
        phit(:,count2)=phi;
        rho_t(:,count2)=p_2-n_2+N_d-N_a;

        % Compute 2D drift and diffusion current densities (element-based)
        [jx_drift_n, jy_drift_n, jx_drift_p, jy_drift_p] = compute_j_drift_2d(gamma_n, gamma_p, n_2, p_2, dphi_dx, dphi_dy, el_2d_no);
        [jx_diff_n, jy_diff_n, jx_diff_p, jy_diff_p, dn_dx, dn_dy, dp_dx, dp_dy] = compute_j_diffusion_2d(gamma_n, gamma_p, n_2, p_2, el_2d_no, x_coords, y_coords);
            
        % Store total and component currents
        jx_nt(:,count2) = jx_drift_n + jx_diff_n;
        jx_pt(:,count2) = jx_drift_p + jx_diff_p;
        jx_drift_nt(:,count2) = jx_drift_n;
        jx_drift_pt(:,count2) = jx_drift_p;
        jx_diff_nt(:,count2) = jx_diff_n;
        jx_diff_pt(:,count2) = jx_diff_p;

        jy_nt(:,count2) = jy_drift_n + jy_diff_n;
        jy_pt(:,count2) = jy_drift_p + jy_diff_p;
        jy_drift_nt(:,count2) = jy_drift_n;
        jy_drift_pt(:,count2) = jy_drift_p;
        jy_diff_nt(:,count2) = jy_diff_n;
        jy_diff_pt(:,count2) = jy_diff_p;
        
        jx_total = jx_nt(:,count2) + jx_pt(:,count2);
        jy_total = jy_nt(:,count2) + jy_pt(:,count2);
        
        I_norm(count2) = compute_contact_current(el_2d_no, x_coords, y_coords, ...
                                            jx_total, jy_total, ...
                                            H1, H2, e_start, e_end,L_n, tol);     % dimensionless
        device_thickness = 1e-4; % cm
        I_drift_diff = I_norm(count2) * Jo * Lo * device_thickness;
                        %    []       * [A/cm^2] * [cm] * [cm] = [A]

        V = DBC1 * Vt; 
        J_th_n = An * T^2 * exp(-phiB/(k_B*T)) * (exp(V/Vt) - 1);
        J_th_p = Ap * T^2 * exp(-(Eg-phiB)/(k_B*T)) * (exp(V/Vt) - 1);
        ContactArea = (e_end - e_start) * device_thickness; % cm²
        I_thermionic = (J_th_n + J_th_p) * ContactArea;

        I_top(count2) = I_drift_diff; % Drift+diffusion integrated current (physical)

        % --- Schottky contact emission current using J = -q v (n - n0) ---
        if schottky
            [I_sch(count2), J_sch_density(count2)] = compute_schottky_contact_current( ...
                n_2, p_2, x_coords, y_coords, el_2d_no, H1, H2, e_start, e_end, tol, ...
                vsn, vsp, n_sc, p_sc, Lo, Jo, device_thickness);
        end
        count1=0;
    end
    
end % End of Loop Over Time

%%
if plotcutline
    % Use physical units for cutline plots
    phi_phys = phi * Vt;                 % V
    Eabs_phys = (Vt/Lo) * Eabs;          % V/cm
    n_phys = n_t * n_i;                  % cm^-3
    x_coords_phys = x_coords * Lo;       % cm
    y_coords_phys = y_coords * Lo;       % cm

    cut_x_cm = 0.0004;                   
    plot_cutline_phys(phi_phys, x_coords_phys, y_coords_phys, cut_x_cm, 'x', 200);
    plot_cutline_phys(Eabs_phys, x_coords_phys, y_coords_phys, cut_x_cm, 'x', 200);
    plot_cutline_phys(n_phys, x_coords_phys, y_coords_phys, cut_x_cm, 'x', 200);

    plot_cutline_phys_mesh(phi_phys, x_coords_phys, y_coords_phys, el_2d_no, 4e-4, 'x', 100, 'bary');
    plot_cutline_phys_mesh(n_phys, x_coords_phys, y_coords_phys, el_2d_no, 4e-4, 'x', 100, 'bary');

    % --- Current density cutlines (element-based, physical units A/cm^2) ---
    try
        jx_total_elem = jx_nt(:,count2) + jx_pt(:,count2); % normalized
        jy_total_elem = jy_nt(:,count2) + jy_pt(:,count2); % normalized
        Jx_total_phys = jx_total_elem * Jo;                % A/cm^2
        Jy_total_phys = jy_total_elem * Jo;                % A/cm^2
        Jabs_total_phys = sqrt(Jx_total_phys.^2 + Jy_total_phys.^2);

        % Vertical cut at x = 4e-4 cm: plot Jx (flow across vertical sections) and |J|
        plot_cutline_phys_mesh(Jx_total_phys, x_coords_phys, y_coords_phys, el_2d_no, 4e-4, 'x', 200, 'elemconst');
        plot_cutline_phys_mesh(Jy_total_phys, x_coords_phys, y_coords_phys, el_2d_no, 4e-4, 'x', 200, 'elemconst');
        plot_cutline_phys_mesh(Jabs_total_phys, x_coords_phys, y_coords_phys, el_2d_no, 4e-4, 'x', 200, 'elemconst');
    catch ME
        warning('ddm2d:JCutline', 'Current density cutline plotting skipped: %s', ME.message);
    end
end

%%
% if plot_final_solution
%     % 2D potential distribution
%     figure;
%     trisurf(el_2d_no, x_coords, y_coords, phi, 'EdgeColor', 'none');
%     colorbar; title('2D Potential Distribution'); xlabel('x (cm)'); ylabel('y (cm)');
%     view(2); 

%     % 2D electron concentration
%     figure;
%     trisurf(el_2d_no, x_coords, y_coords, n_2, 'EdgeColor', 'none');
%     colorbar; title('2D Electron Concentration'); xlabel('x (cm)'); ylabel('y (cm)');
%     view(2); 

%     % 2D hole concentration
%     figure;
%     trisurf(el_2d_no, x_coords, y_coords, p_2, 'EdgeColor', 'none');
%     colorbar; title('2D Hole Concentration'); xlabel('x (cm)'); ylabel('y (cm)');
%     view(2); 
% end

%%
if plot_final_solution
    % 2D total current vector field
    figure;
    xc = mean(x_coords(el_2d_no)*Lo, 2);
    yc = mean(y_coords(el_2d_no)*Lo, 2);

    quiver(xc, yc, jx_nt(:,count2), jy_nt(:,count2), 'k');
    title('2D Total Current Density Vector Field');
    xlabel('x (cm)'); ylabel('y (cm)'); 

    % 2D drift current vector field
    figure;
    quiver(xc, yc, jx_drift_nt(:,count2), jy_drift_nt(:,count2), 'r');
    title('2D Drift Current Density Vector Field');
    xlabel('x (cm)'); ylabel('y (cm)'); 

    % 2D diffusion current vector field
    figure;
    quiver(xc, yc, jx_diff_nt(:,count2), jy_diff_nt(:,count2), 'b');
    title('2D Diffusion Current Density Vector Field');
    xlabel('x (cm)'); ylabel('y (cm)'); 

    figure;
    plot(t(1:count2), I_top(1:count2), 'LineWidth', 2);
    xlabel('Time (s)');
    ylabel('Current (A)');
    title('Total Current through Top Electrode');
    grid on;

    if schottky
        figure;
        plot(t(1:count2), I_sch(1:count2), 'r', 'LineWidth', 2); hold on;
        plot(t(1:count2), I_top(1:count2), 'k--', 'LineWidth', 1.5);
        xlabel('Time (s)'); ylabel('Current (A)');
        legend('Schottky Emission (-q v (n-n_0))','FE Drift+Diff');
        title('Schottky Emission Current vs FE Drift-Diffusion Current'); grid on;

        figure;
        plot(t(1:count2), J_sch_density(1:count2), 'b', 'LineWidth', 2);
        xlabel('Time (s)'); ylabel('J (A/cm^2)');
        title('Schottky Contact Current Density J = -q v (n - n_0)'); grid on;
    end


end

%% Comparison
if comp
    comparison('n', Ubias, 'Vjunc');
    comparison('phi', Ubias, 'Vjunc');

    comparison('n', Ubias, 'Vl');
    comparison('phi', Ubias, 'Vl');

    comparison('n', Ubias, 'Vr');
    comparison('phi', Ubias, 'Vr');

    comparison('n', Ubias, 'Hn');
    comparison('phi', Ubias, 'Hn');

    comparison('n', Ubias, 'Hnn');
    comparison('phi', Ubias, 'Hnn');
end

%% Current comparison
if comp
    if schottky
        contactType = 'SO';
    else
        contactType = 'OO';
    end
    cur_comp('drift', Ubias, contactType, 0);
    cur_comp('diff', Ubias, contactType, 0);
    cur_comp('drift', Ubias, contactType);
    cur_comp('diff', Ubias, contactType);
end


