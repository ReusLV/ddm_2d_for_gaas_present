% Field Scalar Plot 2-D with Logarithmic Scale
% Specifically designed for visualizing fields with large value differences


% Create color map
cmap = jet(256);          
colormap(cmap);           

% Determine color scale limits
if exist('V_min_user','var') && exist('V_max_user','var') && isfinite(V_min_user) && isfinite(V_max_user) && V_min_user>0 && V_max_user>V_min_user
    % Use user-provided fixed limits
    V_min = V_min_user;
    V_max = V_max_user;
else
    % Auto range — ensure all values are positive for log scale
    V_min = max(min(V), 1e-12); % Avoid zero or negative values
    V_max = max(V);
    % If min value is too small compared to max, adjust it for better visualization
    if V_min < V_max * 1e-5
        V_min = V_max * 1e-5;
    end
end

% Calculate logarithmic range
log_min = log10(V_min);
log_max = log10(V_max);

% Traverse all triangular elements 
for e = 1:Nel
    % Extract the nodes of the triangular element
    nodes = el_2d_no(e, :);  % Store the node indices of the element (3 nodes for triangle)
    
    % Extract the coordinates and values of the nodes
    x_corners = x_coords(nodes);    % x-coordinates of the 3 vertices
    y_corners = y_coords(nodes);    % y-coordinates of the 3 vertices
    V_corners = V(nodes);           % values of the 3 vertices
    
    % Mean value of the 3 vertices
    V_avg = mean(V_corners);
    
    % Ensure value is positive for log scale
    V_avg = max(V_avg, V_min);
    
    % Map the value to a color using logarithmic scale
    log_val = log10(V_avg);
    color_idx = round((log_val - log_min) / (log_max - log_min) * (size(cmap,1)-1)) + 1;
    
    % Ensure color index is within valid range
    color_idx = max(1, min(color_idx, size(cmap,1)));
    color = cmap(color_idx, :);  % Color of the element 
    
    % Draw the triangular element
    patch('XData', x_corners, 'YData', y_corners, ...
            'FaceColor', color, 'EdgeColor', 'none');
end

% Add a colorbar with logarithmic scale
h = colorbar;

% Set up logarithmic color axis
caxis([V_min V_max]);
set(gca, 'ColorScale', 'log');

% Force colorbar to show min and max explicitly
try
    % Generate nice tick positions in log space including endpoints
    logTicks = unique(round([log_min, linspace(log_min, log_max, 5), log_max], 6));
    h.Ticks = 10.^logTicks;
    % Use LaTeX-like exponential labels for readability
    h.TickLabels = arrayfun(@(v) sprintf('%.0e', v), h.Ticks, 'UniformOutput', false);
catch
    % Fallback: ensure endpoints at least
    h.Ticks = [V_min V_max];
    h.TickLabels = arrayfun(@(v) sprintf('%.0e', v), h.Ticks, 'UniformOutput', false);
end
