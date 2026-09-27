% Field Scalar Plot 2-D

% for e=1:Ne_1d
    
%     ind1=el_1d_no(e,1);ind2=el_1d_no(e,2);
%     x1=x_no(ind1);x2=x_no(ind2);
%     plot([x1,x2],[V(ind1),V(ind2)],'Color',line_color);
 
% end

% 2d scalar field plot
% figure;
% hold on;

cmap = jet(256);          
colormap(cmap);           
V_min = min(V);
V_max = max(V);

% traversal of all triangular elements 
for e = 1:Nel
    % extract the nodes of the triangular element
    nodes = el_2d_no(e, :);  % store the node indices of the element (3 nodes for triangle)
    
    % extract the coordinates and potential values of the nodes
    x_corners = x_coords(nodes);    % x-coordinates of the 3 vertices
    y_corners = y_coords(nodes);    % y-coordinates of the 3 vertices
    V_corners = V(nodes);           % values of the 3 vertices
    
    % mean potential value of the 3 vertices
    V_avg = mean(V_corners);
    
    % map the mean potential value to a color
    color_idx = round( (V_avg - V_min) / (V_max - V_min) * (size(cmap,1)-1) ) + 1;
    color_idx = min(max(color_idx,1),size(cmap,1)); % ensure index is within bounds
    color = cmap(color_idx, :);  % color of the element 
    
    % draw the triangular element
    patch('XData', x_corners, 'YData', y_corners, ...
          'FaceColor', color, 'EdgeColor', 'none');
end

% Add a colorbar with the actual values
h_colorbar = colorbar;
if V_max == V_min
    caxis([V_min V_min+1e-12]);
elseif V_max > V_min && ~isnan(V_min) && ~isnan(V_max)
    caxis([V_min V_max]);
end

