function plot_hole_concentration_phys(p_phys, iter, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no, varargin)
% PLOT_HOLE_CONCENTRATION_PHYS - Plots hole concentration in physical units (cm^-3).
%
% Syntax: plot_hole_concentration_phys(p_phys, iter, Px1, Py1, Px2, Py2, x_coords, y_coords, el_2d_no, 'CLim',[vmin vmax])
% Optional Name-Value pairs:
%   'CLim'     [vmin vmax] fixes the color scale (in cm^-3) regardless of input data range.
%   'ColorMap' colormap name or matrix (default 'jet').
    % Ensure required variables exist for the plotting script (script uses Nel)
    Nel = size(el_2d_no,1); %#ok<NASGU>
    % Touch to avoid unused warnings but keep available for script
    Px1; Py1; Px2; Py2; iter; %#ok<VUNUS>
    x_coords(1); y_coords(1); %#ok<VUNUS>

    % Parse optional arguments
    p = inputParser;
    addParameter(p,'CLim',[],@(v)isnumeric(v) && numel(v)==2 && all(isfinite(v)));
    addParameter(p,'ColorMap','jet');
    parse(p, varargin{:});
    opts = p.Results;

    f1 = figure('Position',[Px1 Py1 Px2 Py2],'Color',[1 1 1]);
    a1 = axes('Parent',f1);
    V = p_phys; %#ok<NASGU>

    % If user fixes the color scale, expose limits to the plotting script
    if ~isempty(opts.CLim)
        V_min_user = max(min(opts.CLim), eps); %#ok<NASGU>
        V_max_user = max(opts.CLim);          %#ok<NASGU>
        if V_min_user <= 0 || V_min_user >= V_max_user
            warning('plot_hole_concentration_phys:BadCLim', 'Ignoring invalid CLim; using data-driven limits.');
            clear V_min_user V_max_user;
        end
    end

    % Apply colormap preference if provided
    try
        colormap(a1, opts.ColorMap);
    catch
        % fallback to jet if invalid
        colormap(a1, 'jet');
    end

    plot_scalar_field_2d_log;

    xlabel('x (cm)');
    ylabel('y (cm)');
    % No title per requirement; keep axes clear and readable
    set(a1, 'LineWidth', 1.2, 'FontSize', 11);
    cb = colorbar; %#ok<NASGU>

    % If fixed limits were requested, enforce them on the axes (and colorbar)
    if ~isempty(opts.CLim)
        try
            caxis(a1, opts.CLim);
        catch
            % ignore if axes not ready
        end
    end

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
        fileBase = sprintf('%.2fV_%s_%s', Ubias_V, contactSuffix, 'p');
        pngPath  = fullfile(compDir, [fileBase '.png']);
        try
            if exist('exportgraphics','file')
                exportgraphics(gcf, pngPath, 'Resolution', 300);
            else
                saveas(gcf, pngPath);
            end
        catch ME
            warning('plot_hole_concentration_phys:SaveFailed', 'Failed to save figure: %s', ME.message);
        end
    end
end
