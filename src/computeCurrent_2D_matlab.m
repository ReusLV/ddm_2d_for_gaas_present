function [I_total, ...
          I_drift_n, I_diff_n, ...
          I_drift_p, I_diff_p] = ...
          computeCurrent_2D_matlab(el_2d_no, x_coords, y_coords, ...
          phi, n, p, mu_n, mu_p, kb, T, q, ...
          H1, H2, e_start, e_end, tol)

    % Initialize total current and component currents
    I_total   = 0.0;
    I_drift_n = 0.0;
    I_diff_n  = 0.0;
    I_drift_p = 0.0;
    I_diff_p  = 0.0;

    % Gauss points (2-point rule)
    gauss_points  = [-0.577350269, 0.577350269];
    gauss_weights = [1.0, 1.0];

    Ne = size(el_2d_no,1);

    for e = 1:Ne
        nodes = el_2d_no(e,:);
        xe = x_coords(nodes);
        ye = y_coords(nodes);

    % Three edges of the triangle
        edges = [1 2; 2 3; 3 1];

        for k = 1:3
            n1 = edges(k,1); 
            n2 = edges(k,2);

            x1 = xe(n1); y1 = ye(n1);
            x2 = xe(n2); y2 = ye(n2);

            % Check if this edge lies on the top contact window
            if abs(y1-(H1+H2))<tol && abs(y2-(H1+H2))<tol && ...
               x1>=e_start-tol && x1<=e_end+tol && ...
               x2>=e_start-tol && x2<=e_end+tol

                % Identify the local edge index
                if isequal(sort([nodes(n1), nodes(n2)]), sort(nodes([1 2])))
                    local_edge_index = 0; start_node = nodes(1); end_node = nodes(2);
                elseif isequal(sort([nodes(n1), nodes(n2)]), sort(nodes([2 3])))
                    local_edge_index = 1; start_node = nodes(2); end_node = nodes(3);
                else
                    local_edge_index = 2; start_node = nodes(3); end_node = nodes(1);
                end

                % Gaussian quadrature along the edge
                for g = 1:2
                    t = 0.5*(1+gauss_points(g));

                    switch local_edge_index
                        case 0
                            xi = t;   eta = 0.0;
                        case 1
                            xi = 1-t; eta = t;
                        case 2
                            xi = 0.0; eta = 1-t;
                    end

                    % Edge vector and length
                    dx = x_coords(end_node) - x_coords(start_node);
                    dy = y_coords(end_node) - y_coords(start_node);
                    edge_length = sqrt(dx^2 + dy^2);

                    % Outward normal
                    nx = -dy / edge_length;
                    ny = dx / edge_length;

                    % Ensure element orientation is counter-clockwise; flip if not
                    ccw = ((xe(2)-xe(1))*(ye(3)-ye(1)) - (xe(3)-xe(1))*(ye(2)-ye(1))) > 0;
                    if ~ccw
                        nx = -nx; ny = -ny;
                    end

                    % Compute current components at the quadrature point
                    in_node = setdiff(nodes,[start_node,end_node]);
                    [jx_drift_n, jy_drift_n, jx_diff_n, jy_diff_n, ...
                     jx_drift_p, jy_drift_p, jx_diff_p, jy_diff_p] = ...
                     computeCurrentDensity_2D_matlab(start_node, end_node, in_node, ...
                                                     xi, eta, x_coords, y_coords, ...
                                                     phi, n, p, mu_n, mu_p, kb, T, q);

                    % Compose total current density
                    Jx = jx_drift_n + jx_diff_n + jx_drift_p + jx_diff_p;
                    Jy = jy_drift_n + jy_diff_n + jy_drift_p + jy_diff_p;

                    % Normal components
                    Jn_total   = Jx*nx + Jy*ny;
                    Jn_drift_n = jx_drift_n*nx + jy_drift_n*ny;
                    Jn_diff_n  = jx_diff_n*nx  + jy_diff_n*ny;
                    Jn_drift_p = jx_drift_p*nx + jy_drift_p*ny;
                    Jn_diff_p  = jx_diff_p*nx  + jy_diff_p*ny;

                    % Accumulate integral
                    I_total   = I_total   + gauss_weights(g)*Jn_total  *(edge_length/2.0);
                    I_drift_n = I_drift_n + gauss_weights(g)*Jn_drift_n*(edge_length/2.0);
                    I_diff_n  = I_diff_n  + gauss_weights(g)*Jn_diff_n *(edge_length/2.0);
                    I_drift_p = I_drift_p + gauss_weights(g)*Jn_drift_p*(edge_length/2.0);
                    I_diff_p  = I_diff_p  + gauss_weights(g)*Jn_diff_p *(edge_length/2.0);
                end
            end
        end
    end
end
