function plot_potential(phi, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no)
% PLOT_POTENTIAL - Plots the electrostatic potential.
%
% Syntax: plot_potential(phi, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no)
    [Nel,~]=size(el_2d_no);

    f1=figure('Position',[Px1 Py1 Px2 Py2],'Color',[1 1 1]);
    a1=axes('Parent',f1);
    grid on;
    xlabel('x (cm)');
    ylabel('y (cm)');
    title('phi/Vt');
    hold on;
    
    % The script below uses V and other geometry variables from the current workspace
    V=phi;
    plot_scalar_field_2d;
    
end 