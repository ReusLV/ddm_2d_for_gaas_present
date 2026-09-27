function plot_potential_phys(phi_phys, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no)
% PLOT_POTENTIAL_PHYS - Plots the electrostatic potential in physical units (V).
%
% Syntax: plot_potential_phys(phi_phys, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no)

    % Touch inputs to avoid unused warnings in some linters
    [Nel,~] = size(el_2d_no); 
    x_coords(1); y_coords(1);
    
    f1 = figure('Position',[Px1 Py1 Px2 Py2],'Color',[1 1 1]);
    a1 = axes('Parent',f1);
    grid on;
    xlabel('x (cm)');
    ylabel('y (cm)');
    % No title per requirement; keep axes clear and readable
    set(a1, 'LineWidth', 1.2, 'FontSize', 11);
    hold on;

    % The plotting scripts use V and geometry variables from caller workspace
    V = phi_phys; %#ok<NASGU> 
    plot_scalar_field_2d;

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
        fileBase = sprintf('%.2fV_%s_%s', Ubias_V, contactSuffix, 'phi');
        pngPath  = fullfile(compDir, [fileBase '.png']);
        try
            if exist('exportgraphics','file')
                exportgraphics(gcf, pngPath, 'Resolution', 300);
            else
                saveas(gcf, pngPath);
            end
        catch ME
            warning('plot_potential_phys:SaveFailed', 'Failed to save figure: %s', ME.message);
        end
    end
end
