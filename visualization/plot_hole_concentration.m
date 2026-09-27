function plot_hole_concentration(p_t, iter, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no)
% PLOT_HOLE_CONCENTRATION - Plots the hole concentration on a log scale.
%
% Syntax: plot_hole_concentration(p_t, iter, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no)
    [Nel, ~] = size(el_2d_no);

    figure('Position',[Px1 Py1 Px2 Py2],'Color',[1 1 1]);
    
    % The script below uses V and other geometry variables from the current workspace
    V = p_t;
    plot_scalar_field_2d_log;
    
    xlabel('x (cm)');
    ylabel('y (cm)');
    title(['Hole Concentration p/n_i - Iteration ' num2str(iter)]);
    colorbar;            
    
end 