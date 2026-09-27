function I = compute_contact_current(el_2d_no, x_coords, y_coords, jx, jy, H1, H2, e_start, e_end, L_n, tol)
% Compute total current through top contact (y = H1+H2)

I = 0;
Ne = size(el_2d_no,1);

for e=1:Ne
    nodes = el_2d_no(e,:);
    xe = x_coords(nodes);
    ye = y_coords(nodes);

    % Three edges of the triangle
    edges = [1 2; 2 3; 3 1];
    for k=1:3
        n1 = edges(k,1); n2 = edges(k,2);
        x1 = xe(n1); y1 = ye(n1);
        x2 = xe(n2); y2 = ye(n2);

        % Check if it is on the top contact electrode
        % if abs(y1-(H1+H2))<tol && abs(y2-(H1+H2))<tol && ...
        %    x1>=e_start-tol && x1<=e_end+tol && ...
        %    x2>=e_start-tol && x2<=e_end+tol
        
        % Check if it is on the left of the top electrode
        % if abs(y1-(H1+H2))<tol && abs(y2-(H1+H2))<tol && ...
        %    x1>=e_end-tol && x1<=L_n+tol && ...
        %    x2>=e_end-tol && x2<=L_n+tol       

        % Check if it is on the verticle cross section
        if abs(x1 - 0.8*L_n) < tol && abs(x2 - 0.8*L_n) < tol && ...
              y1 >= (0 - tol) && y1 <= (H1 + H2 + tol) && ...
              y2 >= (0 - tol) && y2 <= (H1 + H2 + tol)

            % Edge vector and length
            dx = x2 - x1; dy = y2 - y1;
            L = sqrt(dx^2 + dy^2);

            % Outward normal (normalized)
            nx = -dy / L;
            ny =  dx / L;

            % Average current density (element-based)
            jx_avg = jx(e);
            jy_avg = jy(e);

            % Normal current density
            jn = jx_avg*nx + jy_avg*ny;

            % Add contribution
            I = I + jn * L;
        end
    end
end
end
