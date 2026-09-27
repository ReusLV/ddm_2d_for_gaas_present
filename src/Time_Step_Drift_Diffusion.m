function [n_2,p_2]=Time_Step_Drift_Diffusion(n_1,p_1,F1,F2,G1,S1n,S0n,S1p,S0p,gamma_n,gamma_p,dt,DBC,schottky,st_no,x_coords,y_coords,el_2d_no,L_n,L_nn,H1,H2,e_start,e_end,tol,qn,vsn,vsp,n_sc,p_sc)
% Transient Drift-Diffusion Solver
% Compute the new carrier densities
% Input: 
% F1, F2, G1 - matrices of the drift-diffusion solver
% n_1, p_1 - carrier densities of the previous step
% gamma_n, gamma_p - normalized mobilities
% dt - normalized time step
% DBC(1,4) - Dirichlet BCs for p and n at 3 electrodes
% Tau_n, Tau_p - Time constants of electrons and holes 
% Output:
% n_2, p_2 - carrier densities of the next step

[Nn,M]=size(n_1);
G=zeros(Nn,1);  % recombination rate

% baseline
Kn=F2 - dt*gamma_n*G1 + dt*gamma_n*F1;
Kp=F2 + dt*gamma_p*G1 + dt*gamma_p*F1; 
bn=F2*n_1 + dt*F2*G;
bp=F2*p_1 + dt*F2*G;

% add Schottky BC contributions
% if schottky
%     Kn = Kn + dt*qn*vsn*S1n;
%     Kp = Kp + dt*qn*vsp*S1p;
%     bn = bn + dt*qn*vsn*n_sc*S0n;
%     bp = bp + dt*qn*vsp*p_sc*S0p;
% end
if schottky
    Kn = Kn + dt*S1n;
    Kp = Kp + dt*S1p;
    bn = bn + dt*S0n;
    bp = bp + dt*S0p;
end

boundary_indices = find(st_no == 1);

for i = 1:length(boundary_indices)
    node_idx = boundary_indices(i);
    
    % Ensure index is within valid range
    x = x_coords(node_idx); 
    y = y_coords(node_idx);

    % n-region top electrode - use scalar logical operators & instead of &&
    if abs(y - (H1+H2)) < tol & (x >= e_start) & (x <= e_end)
        if ~schottky
            % fprintf('Warning: Schottky BCs are not enabled, but boundary node found at n-region top electrode.\n');
            bn(node_idx) = DBC(2); % Dirichlet BC on electron concentration for n-region top electrode
            bp(node_idx) = DBC(1); % Dirichlet BC on hole concentration for n-region top electrode
            Kn(node_idx,:) = 0;Kp(node_idx,:) = 0;
            Kn(node_idx,node_idx)=1;Kp(node_idx,node_idx) = 1;
        end

    % n-region right electrode
    elseif abs(x - L_n) < tol & (y >= H1) & (y <= (H1+H2))
        bn(node_idx) = DBC(2); % Dirichlet BC for n-region right electrode
        bp(node_idx) = DBC(1); % Dirichlet BC for n-region right electrode
        Kn(node_idx,:) = 0;Kp(node_idx,:) = 0;
        Kn(node_idx,node_idx)=1;Kp(node_idx,node_idx) = 1;

    % n+-region top electrode
    elseif abs(y - H1) < tol & (x >= L_n) & (x <= L_nn)
        bn(node_idx) = DBC(4); % Dirichlet BC for n+-region top electrode
        bp(node_idx) = DBC(3); % Dirichlet BC for n+-region top electrode
        Kn(node_idx,:) = 0;Kp(node_idx,:) = 0;
        Kn(node_idx,node_idx)=1;Kp(node_idx,node_idx) = 1;

    % Other boundary nodes - apply Neumann boundary condition (insulating/zero flux)
    end
end

% Direct Linear Solver
n_2=Kn\bn;
p_2=Kp\bp;
