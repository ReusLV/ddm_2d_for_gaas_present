% Define geometric parameters
L_nn = 25e-4;            % Length of n+ region (cm)
L_n = 15e-4;             % Length of n region (cm)
L_te1 = 2e-4;            % Length of top electrode (cm)
L_te2 = 10e-4;           % Length of top electrode (cm)
H1 = 2e-4;               % Thickness of n+ region (cm)
H2 = 0.1e-4;               % Thickness of n region (cm)
fineness = 1;            % Mesh fineness factor (1=original, 2=double, etc.) 
factor = 1;
e_start = 3e-4;       % Start of top electrode (cm)
e_end = 5e-4;         % End of top electrode (cm)

% Define mesh sizes separately for n+ and n regions
dx = 1e-8;             % Horizontal element size in n+ region (cm)
x_coords_nn = [linspace(0, e_start, 10), linspace(e_start+dx, e_end, 25), linspace(e_end+dx, 0.8*L_n, 20), linspace(0.8*L_n+dx, 1.2*L_n, 40), linspace(1.2*L_n+dx, L_nn, 30)];
% x_coords_nn = [linspace(0,L_nn,10)];
x_coords_n  = [x_coords_nn(x_coords_nn <= L_n)];

Nx_nn = length(x_coords_nn) - 1;
Nx_n = length(x_coords_n) - 1;

Nnode_x_nn = length(x_coords_nn);
Nnode_x_n = length(x_coords_n);
% Vertical spacing (non-uniform y), strictly separate interface
dy_interface = 1e-8;  
y_coords_nn = [linspace(0, H1 * 0.8 - dy_interface, 8), linspace(H1 * 0.8, H1 * 0.95 - dy_interface, 1), linspace(H1 * 0.95, H1, 10)];
y_coords_n  = linspace(H1 + dy_interface, H1 + H2, 10);

Ny_nn = length(y_coords_nn) - 1;
Ny_n = length(y_coords_n) - 1;

Nnode_y_nn = length(y_coords_nn);
Nnode_y_n = length(y_coords_n);

interface_map = zeros(Nnode_x_n, 1);
overlap_nodes = min(Nnode_x_nn, Nnode_x_n);

% Compute number of nodes and elements
Nnode_nn = Nnode_x_nn * Nnode_y_nn;  % Total nodes in n+ region
Nnode_n = (Nnode_x_n * Nnode_y_n) - overlap_nodes;  % Total nodes in n region (excluding duplicated interface nodes)
Nnode = Nnode_nn + Nnode_n;  % Total number of nodes

Nel_quad_n = Nx_n * Ny_n;  % Number of quadrilateral elements in n region
Nel_quad_nn = Nx_nn * Ny_nn;  % Number of quadrilateral elements in n+ region
Nel = 2 * (Nel_quad_n + Nel_quad_nn);  % Total number of triangular elements

% Node coordinate initialization
x_coords = zeros(Nnode, 1);
y_coords = zeros(Nnode, 1);
el_2d_no = zeros(Nel, 3);
el_mat_2d = zeros(Nel, 1);
ec_2d = zeros(Nel, 2);

% Generate node coordinates for n+ region
node_count = 0;
for j = 1:length(x_coords_nn)
    for i = 1:length(y_coords_nn)
        node_count = node_count + 1;
        x_coords(node_count) = x_coords_nn(j);
        y_coords(node_count) = y_coords_nn(i);

        if i == Nnode_y_nn && j <= overlap_nodes
            interface_map(j) = node_count;
        end
    end
end

% Generate node coordinates for n region
for j = 1:Nnode_x_n
    for i = 2:Nnode_y_n
        node_count = node_count + 1;
        x_coords(node_count) = x_coords_n(j);
        y_coords(node_count) = y_coords_n(i);
    end 
end

% Generate triangular elements
el_count = 0;

% Generate triangular elements for n+ region (lower layer)
for i = 1:Nx_nn
    for j = 1:Ny_nn
        % Four nodes of the quadrilateral
        n1 = (i-1)*Nnode_y_nn + j;      % Bottom-left
        n2 = i*Nnode_y_nn + j;          % Bottom-right
        n3 = i*Nnode_y_nn + (j+1);      % Top-right
        n4 = (i-1)*Nnode_y_nn + (j+1);  % Top-left
        
        % First triangle (n1, n2, n4)
        el_count = el_count + 1;
        el_2d_no(el_count, :) = [n1, n2, n4];
        ec_2d(el_count, 1) = (x_coords(n1) + x_coords(n2) + x_coords(n4)) / 3;
        ec_2d(el_count, 2) = (y_coords(n1) + y_coords(n2) + y_coords(n4)) / 3;
        el_mat_2d(el_count) = 1;  % n+ region
        
        % Second triangle (n2, n3, n4)
        el_count = el_count + 1;
        el_2d_no(el_count, :) = [n2, n3, n4];
        ec_2d(el_count, 1) = (x_coords(n2) + x_coords(n3) + x_coords(n4)) / 3;
        ec_2d(el_count, 2) = (y_coords(n2) + y_coords(n3) + y_coords(n4)) / 3;
        el_mat_2d(el_count) = 1;  % n+ region
    end
end

% Calculate the number of nodes in each column of n region for correct node mapping
n_nodes_per_column = zeros(Nnode_x_n, 1);
n_nodes_per_column(:) = Nnode_y_n - 1;

% Calculate the starting node offset for each column
column_offsets = zeros(Nnode_x_n, 1);
column_offsets(1) = Nnode_nn; % First column offset starts from after all n+ region nodes
for j = 2:Nnode_x_n
    column_offsets(j) = column_offsets(j-1) + n_nodes_per_column(j-1);
end

% Generate triangular elements for n region (upper layer)
for i = 1:Nx_n
    for j = 1:Ny_n
        % Determine the four vertices of the quadrilateral
        if j == 1
            if i < overlap_nodes
                % Interface elements (first row, within n+ region width)
                n1 = interface_map(i);                   % Bottom-left node (from n+ top boundary)
                n2 = interface_map(i+1);                 % Bottom-right node (from n+ top boundary)
                
                % Calculate indices for upper nodes
                n3 = column_offsets(i+1) + (j);         % Top-right node
                n4 = column_offsets(i) + (j);           % Top-left node
            else
                % First row, but beyond n+ region width
                % Special handling: junction between interface and right boundary of n+ region
                n1 = interface_map(i);              % Bottom-left node (from n+ top boundary)
                n2 = column_offsets(i+1);           % Bottom-right node
                n3 = column_offsets(i+1) + 1;       % Top-right node
                n4 = column_offsets(i) + (j);       % Top-left node
            end
        else
            % j > 1, internal nodes
            if i < overlap_nodes
                % Within n+ region width, need to consider shared nodes in first row
                n1 = column_offsets(i) + (j-1);         % Bottom-left node
                n2 = column_offsets(i+1) + (j-1);       % Bottom-right node
                n3 = column_offsets(i+1) + (j);         % Top-right node
                n4 = column_offsets(i) + (j);           % Top-left node
            else
                % Beyond n+ region width
                % Different columns may have different node counts, need special handling for offsets
                % Special handling: junction between interface and right boundary of n+ region
                n1 = column_offsets(i) + (j-1);     % Bottom-left node
                n2 = column_offsets(i+1) + (j);     % Bottom-right node
                n3 = column_offsets(i+1) + (j+1);   % Top-right node
                n4 = column_offsets(i) + (j);       % Top-left node
            end
        end
        
        % First triangle (n1, n2, n4)
        el_count = el_count + 1;
        el_2d_no(el_count, :) = [n1, n2, n4];
        ec_2d(el_count, 1) = (x_coords(n1) + x_coords(n2) + x_coords(n4)) / 3;
        ec_2d(el_count, 2) = (y_coords(n1) + y_coords(n2) + y_coords(n4)) / 3;
        el_mat_2d(el_count) = 2;  % n region
        
        % Second triangle (n2, n3, n4)
        el_count = el_count + 1;
        el_2d_no(el_count, :) = [n2, n3, n4];
        ec_2d(el_count, 1) = (x_coords(n2) + x_coords(n3) + x_coords(n4)) / 3;
        ec_2d(el_count, 2) = (y_coords(n2) + y_coords(n3) + y_coords(n4)) / 3;
        el_mat_2d(el_count) = 2;  % n region
    end
end

% Check if nodes were correctly generated
% fprintf('Total nodes generated: %d\n', node_count);
% fprintf('Expected nodes: %d\n', Nnode);
% if node_count ~= Nnode
%     warning('Node count mismatch: generated %d, expected %d', node_count, Nnode);
% end

% Add debugging: find potential invalid triangular elements
invalid_triangles = 0;
for i = 1:Nel
    if any(el_2d_no(i, :) > Nnode) || any(el_2d_no(i, :) <= 0)
        invalid_triangles = invalid_triangles + 1;
        fprintf('Invalid triangle at index %d: [%d, %d, %d]\n', ...
            i, el_2d_no(i, 1), el_2d_no(i, 2), el_2d_no(i, 3));
    end
end

if invalid_triangles > 0
    warning('Found %d invalid triangles with out-of-bounds node indices', invalid_triangles);
end


% Normalize
global Lo; 
x_coords = x_coords / Lo;
y_coords = y_coords / Lo;
ec_2d(:,1) = ec_2d(:,1) / Lo;
ec_2d(:,2) = ec_2d(:,2) / Lo;

L_nn = L_nn / Lo;
L_n = L_n / Lo;
L_te1 = L_te1 / Lo;
L_te2 = L_te2 / Lo;
H1 = H1 / Lo;
H2 = H2 / Lo;
e_start = e_start / Lo;
e_end = e_end / Lo;

fprintf('Total nodes generated: %d\n', Nnode);
fprintf('Total triangular elements: %d\n', Nel);
