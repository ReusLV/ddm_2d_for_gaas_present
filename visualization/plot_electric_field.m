function plot_electric_field(Eabs, Nnode, Nel, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no)
% PLOT_ELECTRIC_FIELD - Plots the absolute electric field.
%
% Syntax: plot_electric_field(Eabs, Nnode, Nel, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no)
    f1=figure('Position',[Px1 Py1 Px2 Py2],'Color',[1 1 1]);
    a1=axes('Parent',f1);
    grid on;
    xlabel('x (cm)');
    ylabel('y (cm)');
    title('E*Lo/Vt');
    hold on;
    V= Eabs; % Use Eabs directly for plotting
    
    % plot_scalar_field_2d;

    % Find min and max field values
    find_min_max;
    
    % % Call the plotting function
    field_plot_filled;
    % field_plot_log_filled(V, x_coords, y_coords, el_2d_no, Nel, min_field, max_field);
    % % colorbar;
    
    Ncb_level = 3;

    cb = colorbar(a1,'EastOutside');
    ticks_real = linspace(min_field,max_field,Ncb_level);
    cb.Ticks = (ticks_real - min_field) / (max_field - min_field);
    cb.TickLabels = arrayfun(@(x) sprintf('%.3g',x), ticks_real, 'uni', 0);
    cb.Color = [0 0 0];
    cb.FontSize = 10;
    cb.Position(3) = cb.Position(3) * 0.5;
    fig_pos = f1.Position;
    axes_margin = 0.12; 
    colorbar_margin = 0.18; 
    axes_width = 1 - axes_margin - colorbar_margin;
    axes_height = 0.8;
    set(a1, 'Position', [axes_margin, 0.1, axes_width, axes_height]);

end 