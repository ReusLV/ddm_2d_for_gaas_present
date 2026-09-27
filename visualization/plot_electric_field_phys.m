function plot_electric_field_phys(Eabs_phys, Nnode, Nel, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no)
% PLOT_ELECTRIC_FIELD_PHYS - Plots the electric field magnitude in physical units (V/cm).
%
% Syntax: plot_electric_field_phys(Eabs_phys, Nnode, Nel, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no)
    f1 = figure('Position',[Px1 Py1 Px2 Py2],'Color',[1 1 1]);
    a1 = axes('Parent',f1);
    grid on;
    xlabel('x (cm)');
    ylabel('y (cm)');
    % No title per requirement; keep axes clear and readable
    set(a1, 'LineWidth', 1.2, 'FontSize', 11, 'Box','on', 'Layer','top', 'TickDir','out', ...
        'XAxisLocation','bottom', 'YAxisLocation','left');
    hold on;

    % Touch inputs to avoid unused warnings
    Nnode; Nel; x_coords(1); y_coords(1); el_2d_no(1); %#ok<VUNUS>
    V = Eabs_phys; %#ok<NASGU>

    % Determine min/max for color mapping
    find_min_max;

    % Filled plot of the field
    field_plot_filled;

    % Colorbar formatting
    Ncb_level = 3;
    cb = colorbar(a1,'EastOutside');
    ticks_real = linspace(min_field,max_field,Ncb_level);
    cb.Ticks = (ticks_real - min_field) / (max_field - min_field);
    cb.TickLabels = arrayfun(@(x) sprintf('%.3g',x), ticks_real, 'uni', 0);
    cb.Color = [0 0 0];
    cb.FontSize = 10;
    cb.Position(3) = cb.Position(3) * 0.5;
    fig_pos = f1.Position; %#ok<NASGU>
    axes_margin = 0.12; 
    colorbar_margin = 0.18; 
    axes_width = 1 - axes_margin - colorbar_margin;
    axes_height = 0.74;    % slightly shorter to leave more bottom room
    bottom_margin = 0.16;  % increase bottom margin so x-axis and label are visible
    set(a1, 'Position', [axes_margin, bottom_margin, axes_width, axes_height]);

    % ---- Auto-save under results/comparisons (guarded by save switch) ----
    try
        do_save = evalin('base','exist(''save_figs'',''var'') && isequal(save_figs,1)');
    catch
        do_save = false;
    end
    if do_save
        contactSuffix = 'SO';
        try
            if evalin('base','exist(''schottky'',''var'') && isequal(schottky,0)')
                contactSuffix = 'OO';
            end
        catch
            % keep default
        end
        Ubias_V = 0;
        try
            if evalin('base','exist(''Ubias_V'',''var'')')
                Ubias_V = evalin('base','Ubias_V');
            elseif evalin('base','exist(''Ubias'',''var'')')
                Ubias_V = evalin('base','Ubias');
            end
        catch
            Ubias_V = 0;
        end
        projectRoot = fileparts(fileparts(mfilename('fullpath')));
        compDir = fullfile(projectRoot, 'results', 'comparisons');
        if ~exist(compDir, 'dir'), mkdir(compDir); end
        fileBase = sprintf('%.2fV_%s_%s', Ubias_V, contactSuffix, 'E');
        pngPath  = fullfile(compDir, [fileBase '.png']);
        try
            if exist('exportgraphics','file')
                exportgraphics(f1, pngPath, 'Resolution', 300);
            else
                saveas(f1, pngPath);
            end
        catch ME
            warning('plot_electric_field_phys:SaveFailed', 'Failed to save figure: %s', ME.message);
        end
    end
end
