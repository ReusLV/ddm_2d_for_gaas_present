function I = compute_vertical_line_current(el_2d_no, x_coords, y_coords, jx, x0, y_min, y_max, tol)
% compute_vertical_line_current
% Integrate current density Jx along the vertical line x = x0 from y_min to y_max.
% This computes I = \int_{y_min}^{y_max} Jx(x0, y) dy, assuming unit thickness (2D model).
%
% Inputs
%   el_2d_no : (Ne x 3) element connectivity (triangles, node indices)
%   x_coords : (Nn x 1) x-coordinates of nodes
%   y_coords : (Nn x 1) y-coordinates of nodes
%   jx       : (Ne x 1) element-averaged Jx for each triangle (A/m^2)
%   x0       : scalar, x-position of the vertical cut (same units as x_coords)
%   y_min    : lower y bound of the cut (same units as y_coords)
%   y_max    : upper y bound of the cut (same units as y_coords)
%   tol      : tolerance for geometric tests (same units as coords)
%
% Output
%   I        : total current crossing the vertical line (A/m, per unit thickness)
%
% Notes
% - This method is robust even if the mesh does NOT contain edges exactly on x = x0.
% - It avoids double-counting when the cut coincides with interior mesh edges by
%   including colinear (vertical) edges only from the triangle whose centroid is
%   on the left side of the cut (xc < x0). The sign convention is positive for
%   flow in +x direction (uses Jx only).
%
% Example
%   % If your x/y are in micrometers, pass y_min=0, y_max=2.1 (um). If in meters, use 2.1e-6.
%   I = compute_vertical_line_current(el_2d_no, x_coords, y_coords, jx, 0.8*L_n, 0, 2.1, 1e-9);
%

I = 0;
Ne = size(el_2d_no, 1);

for e = 1:Ne
    nodes = el_2d_no(e, :);
    xe = x_coords(nodes);
    ye = y_coords(nodes);

    % Quick reject by x bounding box
    xmin = min(xe); xmax = max(xe);
    if x0 < (xmin - tol) || x0 > (xmax + tol)
        continue;
    end

    % Collect intersections with non-vertical edges
    yints = [];
    for k = 1:3
        i1 = k; i2 = mod(k,3) + 1;
        x1 = xe(i1); y1 = ye(i1);
        x2 = xe(i2); y2 = ye(i2);
        dx = x2 - x1;

        % Non-vertical edge: compute intersection where x=x0
        if abs(dx) > tol
            t = (x0 - x1) / dx;
            if t >= -tol && t <= 1 + tol
                yint = y1 + t * (y2 - y1);
                yints(end+1,1) = yint; %#ok<AGROW>
            end
        end
    end

    % Deduplicate intersections within tol and sort
    if ~isempty(yints)
        yints = sort(yints);
        yy = yints(1);
        for m = 2:numel(yints)
            if abs(yints(m) - yy(end)) > tol
                yy(end+1,1) = yints(m); %#ok<AGROW>
            end
        end
        yints = yy;
    end

    % Check for colinear vertical edge(s) on x = x0
    colinear_segment = [];
    for k = 1:3
        i1 = k; i2 = mod(k,3) + 1;
        x1 = xe(i1); x2 = xe(i2);
        if abs(x1 - x0) <= tol && abs(x2 - x0) <= tol
            y1 = ye(i1); y2 = ye(i2);
            ylo = min(y1, y2); yhi = max(y1, y2);
            colinear_segment = [ylo, yhi];
            break;
        end
    end

    % Determine the in-triangle vertical segment
    hasSeg = false;
    yseg_lo = 0; yseg_hi = 0;
    if numel(yints) >= 2
        yseg_lo = yints(1); yseg_hi = yints(end);
        hasSeg = true;
    elseif ~isempty(colinear_segment)
        % Include only once to avoid double-counting shared edges
        xc = mean(xe);
        if xc < x0
            yseg_lo = colinear_segment(1); yseg_hi = colinear_segment(2);
            hasSeg = true;
        end
    end

    if hasSeg
        % Clip to requested y-range
        ylo = max(yseg_lo, y_min - tol);
        yhi = min(yseg_hi, y_max + tol);
        if yhi > ylo
            I = I + jx(e) * (yhi - ylo);
        end
    end
end

end
