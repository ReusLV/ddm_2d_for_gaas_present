function [phi]=solve_Poisson_problem(F1,F2,p,n,N_a,N_d,DBC1,DBC2,DBC3,x_coords,y_coords,st_no,H1,H2,L_n,L_nn,e_start,e_end)
% Poisson 2-D Solver
% Input
% p(Nn,1) - hole densities at nodes
% n(Nn,1) - electron densities at nodes
% F1(Nn,Nn) - Sparse dNi*dNj matrix
% F2(Nn,Nn) - Sparse Ni*Nj matrix
% N_a(Nn,1) - Concentration od acceptor atoms
% N_d(Nn,1) - Concentration of donor atoms
% DBC1,DBC2,DBC3 - Dirichlet BC values at different electrode boundaries
% Output
% phi(Nn,1) - Electric scalar potential

[Nn,~]=size(p);

% Add at the beginning of function
% fprintf('Global variables: H1=%e, H2=%e, L_n=%e, L_nn=%e, e_start=%e, e_end=%e\n',...
%          H1, H2, L_n, L_nn, e_start, e_end);
% fprintf('Coordinate range: x_min=%e, x_max=%e, y_min=%e, y_max=%e\n',...
%          min(x_coords), max(x_coords), min(y_coords), max(y_coords));

% Get boundary nodes
% % RHS-side
b=F2*(p-n+N_d-N_a);

% fprintf('Initial b vector: min=%e, max=%e, mean=%e\n', min(b), max(b), mean(abs(b)));

% Set geometric boundary tolerance
tol = 1e-8;

% Process boundary nodes - apply Dirichlet BC at electrodes and Neumann BC elsewhere
% for i = 1:length(boundary_indices)
%     node_idx = boundary_indices(i);
    
%     % Ensure index is within valid range
%     x = x_coords(node_idx); 
%     y = y_coords(node_idx);

%     % n-region top electrode - use scalar logical operators & instead of &&
%     if abs(y - (H1+H2)) < tol & (x >= e_start) & (x <= e_end)
%         b(node_idx) = DBC1; % Dirichlet BC for n-region top electrode
%         F1(node_idx,:) = 0;
%         F1(node_idx,node_idx) = 1;

%     % n-region right electrode
%     elseif abs(x - L_n) < tol & (y >= H1) & (y <= (H1+H2))
%         b(node_idx) = DBC2; % Dirichlet BC for n-region right electrode
%         F1(node_idx,:) = 0;
%         F1(node_idx,node_idx) = 1;

%     % n+-region top electrode
%     elseif abs(y - H1) < tol & (x >= L_n) & (x <= L_nn)
%         b(node_idx) = DBC3; % Dirichlet BC for n+-region top electrode
%         F1(node_idx,:) = 0;
%         F1(node_idx,node_idx) = 1;

%     % Other boundary nodes - apply Neumann boundary condition (insulating/zero flux)
%     else
%         % For Neumann BC (∂φ/∂n = 0), we don't need to modify the matrix
%         % We keep the original equation at these nodes (natural boundary condition)

%     end
% end


for i=1:Nn
    if st_no(i)==1 % Boundary node
        x = x_coords(i); y = y_coords(i);

        isElectrode = false; Phi = 0; % Phi will only be used if on an electrode
        % Electrode segments (Dirichlet):
        if abs(y - (H1+H2)) < tol & (x >= e_start) & (x <= e_end)
            Phi = DBC1; isElectrode = true; % top electrode in n-region
        elseif abs(x - L_n) < tol & (y >= H1) & (y <= (H1+H2))
            Phi = DBC2; isElectrode = true; % right electrode in n-region
        elseif abs(y - H1) < tol & (x >= L_n) & (x <= L_nn)
            Phi = DBC3; isElectrode = true; % top electrode in n+ region
        end

        if isElectrode
            % Enforce Dirichlet BC only on electrode nodes
            F1(i,:) = 0;
            F1(i,i) = 1;
            b(i) = Phi;
        else
            % Non-electrode boundary: keep as natural (Neumann) boundary
        end
    end % Boundary node
end

% Direct Solver
phi=F1\b;


