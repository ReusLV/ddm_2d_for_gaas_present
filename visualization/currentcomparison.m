function currentcomparison(kind, Ubias, suffix, onlyElectrode, data)
% currentcomparison — Compare simulated cutline current density with COMSOL reference
% Usage examples:
%   currentcomparison('drift', 0.5)
%   currentcomparison('diff',  0.5)
%   currentcomparison('tot',   1.0)
%   currentcomparison('tot', 0.5, 'OO', true, dataStruct)  % pass data struct directly
% Notes:
%   - COMSOL reference files are expected in comsol_reference/cutline/top_electrode as
%       JdriftY-<Ubias>V-<suffix>.txt and JdiffY-<Ubias>V-<suffix>.txt
%     with first column: arc length (um), second: current density (A/cm^2).
%   - Simulation currents are element-centered and expected normalized; we scale by Jo (A/cm^2).
%   - This script focuses on the top electrode horizontal cut (y = const), comparing the Y-component (Jy).
% Optional parameter 'data' (struct) can override base workspace variables to avoid recomputation:
%   Required geometry fields if base does not supply them: x_coords, y_coords, el_2d_no, Lo, Jo
%   Optional current fields: jy_drift, jy_diff, jy_total, jy_drift_nt, jy_drift_pt, ... etc.
%   Optional edge window: H1, H2, e_start, e_end, tol

    if nargin < 1 || isempty(kind),   kind   = 'drift'; end
    if nargin < 2 || isempty(Ubias)
        if evalin('base','exist(''Ubias_V'',''var'')')
            Ubias = evalin('base','Ubias_V');
        elseif evalin('base','exist(''Ubias'',''var'')')
            Ubias = evalin('base','Ubias');
        else
            Ubias = 0.5;
        end
    end
    % This script focuses on the top electrode region
    region = 'top_electrode';
    if nargin < 4 || isempty(onlyElectrode), onlyElectrode = false; end
    if nargin < 5, data = []; end

    if ~isempty(data) && ~isstruct(data)
        error('The 5th argument (data) must be a struct if provided.');
    end

    function tf = hasDataField(fn)
        tf = ~isempty(data) && isfield(data, fn) && ~isempty(data.(fn));
    end
    % Workspace access helpers: prefer caller (the function that invoked currentcomparison)
    function tf = ws_exist_local(name)
        % Try caller, then base
        tf = evalin('caller', sprintf('exist(''%s'',''var'')', name)) ~= 0 || ...
             evalin('base',   sprintf('exist(''%s'',''var'')', name)) ~= 0;
    end
    function val = ws_get_local(name)
        if evalin('caller', sprintf('exist(''%s'',''var'')', name))
            val = evalin('caller', name);
        else
            val = evalin('base', name);
        end
    end
    function val = getVar(fn)
        if hasDataField(fn)
            val = data.(fn);
        else
            if ws_exist_local(fn)
                val = ws_get_local(fn);
            else
                error('Missing required variable %s (not in data struct nor base workspace).', fn);
            end
        end
    end
    if nargin < 3 || isempty(suffix)
        % Default OO; if base has schottky==1, use SO
        suffix = 'OO';
        try
            if evalin('base','exist(''schottky'',''var'') && isequal(schottky,1)')
                suffix = 'SO';
            end
        catch
        end
    end
    % Top line fallback is allowed: if top has no valid samples, slightly move inward once

    kind = lower(string(kind));
    if ~ismember(kind, ["drift","diff","tot"])
        error('kind must be one of: drift, diff, tot');
    end

    % ===== Pull required base variables =====
    req = {'x_coords','y_coords','Lo','el_2d_no','Jo'};
    for k=1:numel(req)
        if ~(hasDataField(req{k}) || ws_exist_local(req{k}))
            error('Missing variable %s (supply via data struct / caller / base).', req{k});
        end
    end
    x_coords = getVar('x_coords');
    y_coords = getVar('y_coords');
    Lo       = getVar('Lo');
    el_2d_no = getVar('el_2d_no');
    Jo       = getVar('Jo'); % A/cm^2

    % Element centroids (cm)
    xc_cm = mean(x_coords(el_2d_no), 2) * Lo;
    yc_cm = mean(y_coords(el_2d_no), 2) * Lo;

    % ===== Gather element-wise current components (normalized) =====
    % Priority 1: use your exact variable names saved in the main loop
    % If user passed direct arrays in data, use them first
    jy_drift = []; jy_diff = []; ok_drift = false; ok_diff = false;
    if hasDataField('jy_drift')
        jy_drift = data.jy_drift(:); ok_drift = numel(jy_drift)==size(el_2d_no,1);
        if ~ok_drift
            warning('Size mismatch for data.jy_drift (expected %d). Ignoring provided vector.', size(el_2d_no,1));
            ok_drift = false; jy_drift = [];
        end
    end
    if hasDataField('jy_diff')
        jy_diff = data.jy_diff(:); ok_diff = numel(jy_diff)==size(el_2d_no,1);
        if ~ok_diff
            warning('Size mismatch for data.jy_diff (expected %d). Ignoring provided vector.', size(el_2d_no,1));
            ok_diff = false; jy_diff = [];
        end
    end
    if ~ok_drift || ~ok_diff
        [jy_drift2, ok_drift2] = i_get_by_user_names('drift');
        if ~ok_drift && ok_drift2, jy_drift = jy_drift2; ok_drift = true; end
        [jy_diff2, ok_diff2 ] = i_get_by_user_names('diff');
        if ~ok_diff && ok_diff2,  jy_diff = jy_diff2;  ok_diff  = true; end
    end
    source_drift = ''; source_diff = ''; source_tot = '';
    if ok_drift && hasDataField('jy_drift'), source_drift = 'data.jy_drift'; end
    if ok_diff  && hasDataField('jy_diff'),  source_diff  = 'data.jy_diff';  end
    if ~ok_drift
        % Try discovering arrays saved by the main function via name patterns
        [jy_drift, ok_drift, src_pd] = i_discover_by_pattern('drift', size(el_2d_no,1));
        if ok_drift, source_drift = ['pattern:' src_pd]; end
        if ~ok_drift
            % Fallback: robust helper that tries *_tot, *_n+*_p, *_nt/pt
            [~, jy_drift, ok_drift] = i_get_current_component('drift');
            if ok_drift, source_drift = 'component_fallback'; end
        end
    end
    if ~ok_diff
        [jy_diff, ok_diff, src_pd] = i_discover_by_pattern('diff', size(el_2d_no,1));
        if ok_diff, source_diff = ['pattern:' src_pd]; end
        if ~ok_diff
            [~, jy_diff, ok_diff] = i_get_current_component('diff');
            if ok_diff, source_diff = 'component_fallback'; end
        end
    end

    switch kind
        case 'drift'
            if ~ok_drift, error('Drift current arrays not found in base workspace (tried jy_drift_tot, jy_drift_n/p, jy_drift_nt/pt).'); end
            qy = jy_drift; label = 'J_y, drift (A/cm^2)'; baseName = 'JdriftY';
        case 'diff'
            if ~ok_diff, error('Diffusion current arrays not found in base workspace (tried jy_diff_tot, jy_diff_n/p, jy_diff_nt/pt).'); end
            qy = jy_diff; label = 'J_y, diff (A/cm^2)'; baseName = 'JdiffY';
        case 'tot'
            % Try your 'jy_total' first, then generic total helper, then drift+diff
            % Direct provided total overrides everything
            if hasDataField('jy_total')
                jy_tot = data.jy_total(:); ok_tot = numel(jy_tot)==size(el_2d_no,1); source_tot = 'data.jy_total';
                if ~ok_tot
                    warning('Size mismatch for data.jy_total (expected %d). Ignoring provided vector.', size(el_2d_no,1));
                    ok_tot = false; jy_tot = [];
                end
            else
                [jy_tot, ok_tot] = i_get_total_by_user_names();
                if ok_tot, source_tot = 'user_names_total'; end
            end
            if ~ok_tot
                % Try discover total first
                [jy_tot, ok_tot, src_pd] = i_discover_by_pattern('tot', size(el_2d_no,1));
                if ok_tot
                    source_tot = ['pattern:' src_pd];
                else
                    [~, jy_tot, ok_tot] = i_get_current_total();
                    if ok_tot, source_tot = 'total_component_fallback'; end
                end
            end
            if ok_tot
                qy = jy_tot;
            elseif ok_drift && ok_diff
                qy = jy_drift + jy_diff;
                source_tot = 'drift+diff_sum';
            else
                error('Total current not available: need jy_nt/jy_pt or drift+diff components.');
            end
            label = 'J_y, total (A/cm^2)'; baseName = 'JtotY';
    end

    % Logging of sources
    if strcmp(kind,'drift') && ~isempty(source_drift)
        fprintf('[currentcomparison] matched drift source = %s\n', source_drift);
    elseif strcmp(kind,'diff') && ~isempty(source_diff)
        fprintf('[currentcomparison] matched diff source  = %s\n', source_diff);
    elseif strcmp(kind,'tot') && ~isempty(source_tot)
        fprintf('[currentcomparison] matched total source = %s\n', source_tot);
        if ~isempty(source_drift)
            fprintf('  (drift sub-source = %s)\n', source_drift);
        end
        if ~isempty(source_diff)
            fprintf('  (diff  sub-source = %s)\n', source_diff);
        end
    end

    % Scale to A/cm^2 (normalized -> physical)
    Jy_sim = qy * Jo;
    % Determine if user wants to disable physics fallback
    disableFallback = false;
    if hasDataField('disableFallback') && islogical(data.disableFallback)
        disableFallback = data.disableFallback;
    elseif ws_exist('cc_disableFallback')
        val_df = ws_get('cc_disableFallback');
        if islogical(val_df), disableFallback = val_df; end
    end
    % Fallback condition: (no finite) OR (all exactly zero) OR (max below tiny threshold)
    finiteMask = isfinite(Jy_sim);
    if any(finiteMask)
        maxAbsRaw = max(abs(Jy_sim(finiteMask)));
        nonZeroCount = nnz(abs(Jy_sim) > 0);
        allZero = (nonZeroCount == 0);
    else
        maxAbsRaw = 0; nonZeroCount = 0; allZero = true;
    end
    tinyThresh = 1e-40; % extremely small physical current threshold
    needFallback = (~any(finiteMask)) || allZero || (maxAbsRaw < tinyThresh);
    if needFallback && ~disableFallback
        if ~any(finiteMask)
            fb_reason = 'no finite values';
        elseif allZero
            fb_reason = 'all exact zeros';
        else
            fb_reason = sprintf('max |Jy|=%.3e < %.1e', maxAbsRaw, tinyThresh);
        end
        i_report_candidates(kind, size(el_2d_no,1));
        fprintf('[currentcomparison] Fallback trigger (%s): finite=%d, nonZero=%d, max=%.3e\n', ...
            fb_reason, nnz(finiteMask), nonZeroCount, maxAbsRaw);
        try
            fprintf('[currentcomparison] Fallback: computing Jy from fields (phi,n,p) at centroids...\n');
            Jy_sim = i_compute_Jy_from_fields(kind);
        catch ME
            warning('%s: %s', ME.identifier, ME.message);
        end
    elseif needFallback && disableFallback
        warning('[currentcomparison] Detected near-zero/empty Jy (max=%.3e) but fallback disabled; proceeding with zeros.', maxAbsRaw);
    end

    % ===== Determine cutline: region 'top_electrode' -> horizontal at the top boundary (y = y_max) =====
    cut_dir = 'x'; % horizontal
    y_max_cm = max(y_coords(:)) * Lo; % top boundary, e.g., 2.1 um => 2.1e-4 cm
    cut_y_cm = y_max_cm; % use exact top boundary as requested

    % First try: use the exact top-electrode edge filter (same as compute_contact_current)
    x_axis_cm = [];
    Jy_cut_sim = [];
    try
        % pull geometry window and tolerance (prefer data struct, then caller, then base)
        need = {'H1','H2','e_start','e_end','tol'};
        ok_need = true;
        vals = struct();
        for kk=1:numel(need)
            key = need{kk};
            if hasDataField(key)
                vals.(key) = data.(key);
            elseif ws_exist_local(key)
                vals.(key) = ws_get_local(key);
            else
                ok_need = false; break;
            end
        end
        if ok_need
            H1 = vals.H1; H2 = vals.H2; e_start = vals.e_start; e_end = vals.e_end; tol = vals.tol;
            [x_axis_cm, Jy_cut_sim] = i_extract_top_edge_centroid(x_coords, y_coords, el_2d_no, Jy_sim, H1, H2, e_start, e_end, tol, Lo, onlyElectrode);
        end
    catch ME
        warning('%s: %s', ME.identifier, ME.message);
    end

    % Then try a thin band sampling around the exact top line to avoid boundary extrapolation
    axis_range = [];
    if strcmpi(region,'top_electrode') && lower(cut_dir)=='x'
        if exist('ok_need','var') && ok_need && onlyElectrode
            axis_range = [e_start*Lo, e_end*Lo];
        else
            % Limit x to [0, 15 um]
            axis_range = [0, 15e-4]; % cm
        end
    end

    % ===== Read COMSOL reference (if present) and convert A/m^2 -> A/cm^2 =====
    [s_ref_cm, Jy_ref] = i_get_comsol_reference(kind, Ubias, suffix, region, baseName);

    % ===== Plot =====
    figure('Name','Current cutline: simulation vs COMSOL');
    % Filter NaNs to avoid empty plots
    mask_plot = isfinite(x_axis_cm) & isfinite(Jy_cut_sim);
    if ~any(mask_plot)
        % fallback: slightly lower the cutline and retry once inside the domain
        dy = max(1e-8, 0.005 * (max(yc_cm) - min(yc_cm))); % small step inward
        cut_y_cm2 = cut_y_cm - dy;
        [x_axis_cm2, Jy_cut_sim2] = i_extract_cutline(xc_cm, yc_cm, Jy_sim, cut_dir, cut_y_cm2, 400, axis_range);
        mask_plot2 = isfinite(x_axis_cm2) & isfinite(Jy_cut_sim2);
        if any(mask_plot2)
            x_axis_cm = x_axis_cm2; Jy_cut_sim = Jy_cut_sim2; mask_plot = mask_plot2; cut_y_cm = cut_y_cm2;
        else
            warning('No valid simulation samples along the top cutline (y=%.3g cm). Consider lowering cut_y slightly.', cut_y_cm);
            return;
        end
    end
    plot(x_axis_cm(mask_plot)*1e4, Jy_cut_sim(mask_plot), 'b-','LineWidth',1.5); hold on; % x in um for readability
    % If onlyElectrode requested, also clip reference to electrode window (assuming horizontal cutline: s ~ x)
    if ~isempty(Jy_ref) && exist('ok_need','var') && ok_need && onlyElectrode
        mask_ref = s_ref_cm >= e_start*Lo & s_ref_cm <= e_end*Lo;
        s_ref_cm = s_ref_cm(mask_ref); Jy_ref = Jy_ref(mask_ref);
    end

    if ~isempty(Jy_ref)
        plot(s_ref_cm*1e4, Jy_ref, 'r--','LineWidth',1.5);
        legend('Simulation','COMSOL','Location','best');
    else
        legend('Simulation','Location','best');
    end
    grid on;
    xlabel('x (\mum)');
    if strcmpi(region,'top_electrode') && lower(cut_dir)=='x'
        if exist('ok_need','var') && ok_need && onlyElectrode
            xlim([e_start*Lo, e_end*Lo]*1e4);
        else
            xlim([0, 15]);
        end
    end
    ylabel(label);
        ax = gca; ax.TitleFontSizeMultiplier = 1.0; % avoid overly large title size
        title(sprintf('Top electrode cut (y=%.3g cm), Ubias=%.2f V, kind=%s, suffix=%s', cut_y_cm, Ubias, kind, suffix), ...
              'Interpreter','none','FontSize',10);

end

%% ===== Helpers =====

function [x_cm, Jy_edge] = i_extract_top_edge_centroid(x_coords, y_coords, el_2d_no, Jy_elem, H1, H2, e_start, e_end, tol, Lo, onlyElectrode)
% Reuse the same top-electrode edge detection as compute_contact_current, but return x along the edge and Jy
% Inputs:
%  - x_coords,y_coords in normalized units; H1,H2,e_start,e_end,tol normalized; Lo for cm
%  - Jy_elem is per-element A/cm^2; we sample at edge midpoint using the element's centroid value
    Ne = size(el_2d_no,1);
    xs = []; Js = [];
    edges = [1 2; 2 3; 3 1];
    ytop = H1 + H2; %#ok<NASGU>
    for e = 1:Ne
        nodes = el_2d_no(e,:);
        xe = x_coords(nodes); ye = y_coords(nodes);
        for k = 1:3
            n1 = edges(k,1); n2 = edges(k,2);
            x1 = xe(n1); y1 = ye(n1); x2 = xe(n2); y2 = ye(n2);
            if abs(y1-(H1+H2)) < tol && abs(y2-(H1+H2)) < tol
                if onlyElectrode
                    inWin = (x1 >= e_start - tol && x1 <= e_end + tol && ...
                             x2 >= e_start - tol && x2 <= e_end + tol);
                    if ~inWin
                        continue;
                    end
                end
                % edge midpoint in cm
                xm = 0.5*(x1+x2) * Lo;
                xs(end+1,1) = xm; %#ok<AGROW>
                Js(end+1,1) = Jy_elem(e);
            end
        end
    end
    if isempty(xs)
        x_cm = []; Jy_edge = [];
    else
        [x_cm, idx] = sort(xs);
        Jy_edge = Js(idx);
    end
end

function [s_cm, Jy_cm2] = i_read_comsol_J(filePath)
    % Read COMSOL current density cutline: arc length (um), J (A/cm^2)
    M = readmatrix(filePath);
    if isempty(M) || size(M,2) < 2
        error('Cannot read COMSOL file: %s', filePath);
    end
    s_cm = M(:,1) * 1e-4;      % um -> cm
    Jy_cm2 = M(:,2);           % A/cm^2
end

function [s_ref_cm, Jy_ref] = i_get_comsol_reference(kind, Ubias, suffix, region, baseName)
    s_ref_cm = []; Jy_ref = [];
    ref_files_used = {};
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    comsolDir = fullfile(projectRoot, 'comsol_reference', 'cutline', region);
    % Determine alternate suffix to try if primary isn't found
    sfx = upper(string(suffix));
    if sfx == "SO"
        altSuffix = "OO";
    else
        altSuffix = "SO";
    end
    if strcmp(kind,'tot')
        driftFile = fullfile(comsolDir, sprintf('JdriftY-%.1fV-%s.txt', Ubias, suffix));
        diffFile  = fullfile(comsolDir, sprintf('JdiffY-%.1fV-%s.txt',  Ubias, suffix));
        hasDrift = exist(driftFile,'file');
        hasDiff  = exist(diffFile, 'file');
        if hasDrift && hasDiff
            [s_cm1, Jy_drift_ref] = i_read_comsol_J(driftFile);
            [s_cm2, Jy_diff_ref ] = i_read_comsol_J(diffFile );
            if numel(s_cm1) >= numel(s_cm2)
                s_ref_cm = s_cm1;
                Jy_ref = Jy_drift_ref + interp1(s_cm2, Jy_diff_ref, s_ref_cm, 'linear','extrap');
            else
                s_ref_cm = s_cm2;
                Jy_ref = Jy_diff_ref + interp1(s_cm1, Jy_drift_ref, s_ref_cm, 'linear','extrap');
            end
            ref_files_used = {driftFile, diffFile};
        else
            % try alternate suffix
            driftFile2 = fullfile(comsolDir, sprintf('JdriftY-%.1fV-%s.txt', Ubias, altSuffix));
            diffFile2  = fullfile(comsolDir, sprintf('JdiffY-%.1fV-%s.txt',  Ubias, altSuffix));
            if exist(driftFile2,'file') && exist(diffFile2,'file')
                [s_cm1, Jy_drift_ref] = i_read_comsol_J(driftFile2);
                [s_cm2, Jy_diff_ref ] = i_read_comsol_J(diffFile2 );
                if numel(s_cm1) >= numel(s_cm2)
                    s_ref_cm = s_cm1;
                    Jy_ref = Jy_drift_ref + interp1(s_cm2, Jy_diff_ref, s_ref_cm, 'linear','extrap');
                else
                    s_ref_cm = s_cm2;
                    Jy_ref = Jy_diff_ref + interp1(s_cm1, Jy_drift_ref, s_ref_cm, 'linear','extrap');
                end
                ref_files_used = {driftFile2, diffFile2};
            end
        end
    else
        fname = sprintf('%s-%.1fV-%s.txt', baseName, Ubias, suffix);
        fpath = fullfile(comsolDir, fname);
        if exist(fpath,'file')
            [s_ref_cm, Jy_ref] = i_read_comsol_J(fpath);
            ref_files_used = {fpath};
        else
            % try alternate suffix
            fname2 = sprintf('%s-%.1fV-%s.txt', baseName, Ubias, altSuffix);
            fpath2 = fullfile(comsolDir, fname2);
            if exist(fpath2,'file')
                [s_ref_cm, Jy_ref] = i_read_comsol_J(fpath2);
                ref_files_used = {fpath2};
            end
        end
    end
    if ~isempty(ref_files_used)
        fprintf('COMSOL reference file(s) used for %s @ %.2f V in region "%s":\n', kind, Ubias, region);
        for i_rf = 1:numel(ref_files_used)
            fprintf('  - %s\n', ref_files_used{i_rf});
        end
    else
        fprintf('No COMSOL reference file found for %s @ %.2f V in region "%s" (suffix=%s).\n', kind, Ubias, region, suffix);
    end
end

function Jy_phys = i_compute_Jy_from_fields(kind)
% Compute per-element Jy (A/cm^2) at centroids from physical fields, as a robust fallback
% Requires base vars: el_2d_no, x_coords, y_coords, phi, n_t, p_t, mu_n, mu_p, kB, T, q, Lo, Vt, n_i
    req = {'el_2d_no','x_coords','y_coords','phi','n_t','p_t','mu_n','mu_p','kB','T','q','Lo','Vt','n_i'};
    for k=1:numel(req)
        if ~ws_exist(req{k}) % (bottom helper scope uses global ws_exist defined later)
            error('Missing %s for physics-based fallback. Provide via data or caller/base.', req{k});
        end
    end
    el = ws_get('el_2d_no');
    x  = ws_get('x_coords') * ws_get('Lo');
    y  = ws_get('y_coords') * ws_get('Lo');
    phi= ws_get('phi') * ws_get('Vt');
    n  = ws_get('n_t') * ws_get('n_i');
    p  = ws_get('p_t') * ws_get('n_i');
    mu_n = ws_get('mu_n'); mu_p = ws_get('mu_p');
    kB = ws_get('kB'); T = ws_get('T'); q = ws_get('q');
    Nel = size(el,1);
    Jy_phys = zeros(Nel,1);
    xi = 1/3; eta = 1/3; % centroid of triangle
    for e = 1:Nel
        id1 = el(e,1); id2 = el(e,2); id3 = el(e,3);
        [~, jy_drift_n, ~, jy_diff_n, ~, jy_drift_p, ~, jy_diff_p] = ...
            computeCurrentDensity_2D_matlab(id1, id2, id3, xi, eta, x, y, phi, n, p, mu_n, mu_p, kB, T, q);
        switch lower(kind)
            case 'drift'
                Jy_phys(e) = jy_drift_n + jy_drift_p;
            case 'diff'
                Jy_phys(e) = jy_diff_n + jy_diff_p;
            case 'tot'
                Jy_phys(e) = jy_drift_n + jy_drift_p + jy_diff_n + jy_diff_p;
        end
    end
    % The computeCurrentDensity_2D_matlab is designed to return physical units consistent
    % with x,y (cm), mobilities (cm^2/V/s), kB (J/K), q (C). The resulting Jy is A/cm^2.
end

function [jy, ok] = i_get_by_user_names(kind)
% Use user-specified names from the main solver loop
% drift:  jy_drift_nt(:,end) + jy_drift_pt(:,end)
% diff:   jy_diff_nt(:,end)  + jy_diff_pt(:,end)
    ok = false; jy = [];
    try
        switch lower(kind)
            case 'drift'
                if ws_exist('jy_drift_nt') && ws_exist('jy_drift_pt')
                    jy_nt = ws_get('jy_drift_nt');
                    jy_pt = ws_get('jy_drift_pt');
                    if ~isempty(jy_nt) && ~isempty(jy_pt)
                        jy = jy_nt(:,end) + jy_pt(:,end);
                        ok = true; return;
                    end
                end
            case 'diff'
                if ws_exist('jy_diff_nt') && ws_exist('jy_diff_pt')
                    jy_nt = ws_get('jy_diff_nt');
                    jy_pt = ws_get('jy_diff_pt');
                    if ~isempty(jy_nt) && ~isempty(jy_pt)
                        jy = jy_nt(:,end) + jy_pt(:,end);
                        ok = true; return;
                    end
                end
        end
    catch
        ok = false;
    end
end

function [jy, ok] = i_get_total_by_user_names()
% Use user-specified total if available, else last columns of jy_nt/jy_pt
    ok = false; jy = [];
    try
        if ws_exist('jy_total')
            val = ws_get('jy_total');
            if ~isempty(val), jy = val; ok = true; return; end
        end
        if ws_exist('jy_nt') && ws_exist('jy_pt')
            jy_nt = ws_get('jy_nt');
            jy_pt = ws_get('jy_pt');
            if ~isempty(jy_nt) && ~isempty(jy_pt)
                jy = jy_nt(:,end) + jy_pt(:,end); ok = true; return;
            end
        end
    catch
        ok = false;
    end
end

function [jx_tot, jy_tot, ok] = i_get_current_total()
    ok = false; jx_tot = []; jy_tot = [];
    try
        if ws_exist('jx_nt') && ws_exist('jx_pt') && ws_exist('jy_nt') && ws_exist('jy_pt')
            jx_nt = ws_get('jx_nt');
            jx_pt = ws_get('jx_pt');
            jy_nt = ws_get('jy_nt');
            jy_pt = ws_get('jy_pt');
            jx_tot = jx_nt(:,end) + jx_pt(:,end);
            jy_tot = jy_nt(:,end) + jy_pt(:,end);
            ok = true; return;
        end
        if ws_exist('jx_drift_tot') && ws_exist('jx_diff_tot') && ws_exist('jy_drift_tot') && ws_exist('jy_diff_tot')
            jx_drift_tot = ws_get('jx_drift_tot');
            jy_drift_tot = ws_get('jy_drift_tot');
            jx_diff_tot  = ws_get('jx_diff_tot');
            jy_diff_tot  = ws_get('jy_diff_tot');
            jx_tot = jx_drift_tot + jx_diff_tot;
            jy_tot = jy_drift_tot + jy_diff_tot;
            ok = true; return;
        end
    catch
        ok = false;
    end
end

function [jx_tot, jy_tot, ok] = i_get_current_component(kind)
    ok = false; jx_tot = []; jy_tot = [];
    try
        switch lower(kind)
            case 'drift'
                if ws_exist('jx_drift_tot') && ws_exist('jy_drift_tot')
                    jx_tot = ws_get('jx_drift_tot');
                    jy_tot = ws_get('jy_drift_tot');
                    ok = true; return;
                end
                if ws_exist('jx_drift_n') && ws_exist('jx_drift_p') && ws_exist('jy_drift_n') && ws_exist('jy_drift_p')
                    jx_n = ws_get('jx_drift_n');
                    jx_p = ws_get('jx_drift_p');
                    jy_n = ws_get('jy_drift_n');
                    jy_p = ws_get('jy_drift_p');
                    jx_tot = jx_n + jx_p; jy_tot = jy_n + jy_p; ok = true; return;
                end
                if ws_exist('jx_drift_nt') && ws_exist('jx_drift_pt') && ws_exist('jy_drift_nt') && ws_exist('jy_drift_pt')
                    jx_n = ws_get('jx_drift_nt');
                    jx_p = ws_get('jx_drift_pt');
                    jy_n = ws_get('jy_drift_nt');
                    jy_p = ws_get('jy_drift_pt');
                    jx_tot = jx_n(:,end) + jx_p(:,end); jy_tot = jy_n(:,end) + jy_p(:,end); ok = true; return;
                end
            case 'diff'
                if ws_exist('jx_diff_tot') && ws_exist('jy_diff_tot')
                    jx_tot = ws_get('jx_diff_tot');
                    jy_tot = ws_get('jy_diff_tot');
                    ok = true; return;
                end
                if ws_exist('jx_diff_n') && ws_exist('jx_diff_p') && ws_exist('jy_diff_n') && ws_exist('jy_diff_p')
                    jx_n = ws_get('jx_diff_n');
                    jx_p = ws_get('jx_diff_p');
                    jy_n = ws_get('jy_diff_n');
                    jy_p = ws_get('jy_diff_p');
                    jx_tot = jx_n + jx_p; jy_tot = jy_n + jy_p; ok = true; return;
                end
                if ws_exist('jx_diff_nt') && ws_exist('jx_diff_pt') && ws_exist('jy_diff_nt') && ws_exist('jy_diff_pt')
                    jx_n = ws_get('jx_diff_nt');
                    jx_p = ws_get('jx_diff_pt');
                    jy_n = ws_get('jy_diff_nt');
                    jy_p = ws_get('jy_diff_pt');
                    jx_tot = jx_n(:,end) + jx_p(:,end); jy_tot = jy_n(:,end) + jy_p(:,end); ok = true; return;
                end
        end
    catch
        ok = false;
    end
end

function [jy, ok, src] = i_discover_by_pattern(kind, Nel)
% Discover likely current arrays in base workspace by name patterns, prefer element-wise and latest time slice
% kind: 'drift' | 'diff' | 'tot'
    % Get list of variables in base
    vars = evalin('base','whos');
    names = string({vars.name});
    src = '';

    % Nested helper (not inside control blocks): fetch and normalize a candidate to Nelx1
    function vec = pick1(nm)
        vec = [];
        if any(names == string(nm))
            val = evalin('base', string(nm));
            if isnumeric(val)
                sz = size(val);
                if isvector(val) && numel(val)==Nel
                    vec = val(:);
                elseif numel(sz)==2 && sz(1)==Nel && sz(2)>=1
                    % pick last column (latest time step)
                    vec = val(:,end);
                end
            end
        end
    end

    try
        switch lower(kind)
            case 'drift'
                v = pick1('jy_drift_tot'); src_loc = 'jy_drift_tot';
                if isempty(v)
                    v1 = pick1('jy_drift_nt'); v2 = pick1('jy_drift_pt'); src_loc = 'jy_drift_nt+jy_drift_pt';
                    if ~isempty(v1) && ~isempty(v2), v = v1+v2; end
                end
                if isempty(v)
                    v1 = pick1('jy_drift_n'); v2 = pick1('jy_drift_p'); src_loc = 'jy_drift_n+jy_drift_p';
                    if ~isempty(v1) && ~isempty(v2), v = v1+v2; end
                end
                if isempty(v)
                    v = pick1('jy_drift'); src_loc = 'jy_drift';
                end
                jy = v; ok = ~isempty(jy); if ok, src = src_loc; end
            case 'diff'
                v = pick1('jy_diff_tot'); src_loc = 'jy_diff_tot';
                if isempty(v)
                    v1 = pick1('jy_diff_nt'); v2 = pick1('jy_diff_pt'); src_loc = 'jy_diff_nt+jy_diff_pt';
                    if ~isempty(v1) && ~isempty(v2), v = v1+v2; end
                end
                if isempty(v)
                    v1 = pick1('jy_diff_n'); v2 = pick1('jy_diff_p'); src_loc = 'jy_diff_n+jy_diff_p';
                    if ~isempty(v1) && ~isempty(v2), v = v1+v2; end
                end
                if isempty(v)
                    v = pick1('jy_diff'); src_loc = 'jy_diff';
                end
                jy = v; ok = ~isempty(jy); if ok, src = src_loc; end
            otherwise
                v = pick1('jy_total'); src_loc = 'jy_total';
                if isempty(v)
                    v = pick1('jy_tot'); src_loc = 'jy_tot';
                end
                if isempty(v)
                    v1 = pick1('jy_nt'); v2 = pick1('jy_pt'); src_loc = 'jy_nt+jy_pt';
                    if ~isempty(v1) && ~isempty(v2), v = v1+v2; end
                end
                jy = v; ok = ~isempty(jy); if ok, src = src_loc; end
        end
    catch
        ok = false; jy = []; src = '';
    end
    if ok && ~isempty(src)
        fprintf('[currentcomparison] pattern matched %s (%s)\n', src, kind);
    end
end

% ===== Global helper fallbacks (for helper functions outside main scope) =====
function i_report_candidates(kind, Nel)
% Diagnostic: show which candidate variables exist and their max abs value
    switch kind
        case 'drift'
            list = {'jy_drift','jy_drift_tot','jy_drift_nt','jy_drift_pt','jy_drift_n','jy_drift_p'};
        case 'diff'
            list = {'jy_diff','jy_diff_tot','jy_diff_nt','jy_diff_pt','jy_diff_n','jy_diff_p'};
        otherwise
            list = {'jy_total','jy_tot','jy_nt','jy_pt','jy_drift','jy_diff'};
    end
    fprintf('[currentcomparison] Candidate scan (%s):\n', kind);
    for i=1:numel(list)
        nm = list{i};
        if ws_exist(nm)
            val = ws_get(nm);
            sz = size(val);
            if isvector(val) && numel(val)==Nel
                mx = max(abs(val));
                shapeInfo = sprintf('%dx1', numel(val));
            elseif ndims(val)==2 && sz(1)==Nel
                mx = max(abs(val(:,end)));
                shapeInfo = sprintf('%dx%d', sz(1), sz(2));
            else
                mx = NaN; shapeInfo = sprintf('%s (size mismatch)', mat2str(sz));
            end
            fprintf('  %-14s exists, shape=%s, max(abs)=%.3e\n', nm, shapeInfo, mx);
        else
            fprintf('  %-14s (missing)\n', nm);
        end
    end
end

function tf = ws_exist(name)
% Check existence in caller first (which would be currentcomparison when helpers run), then base
try
    tf = evalin('caller', sprintf('exist(''%s'',''var'')', name)) ~= 0;
catch
    tf = false;
end
if ~tf
    tf = evalin('base', sprintf('exist(''%s'',''var'')', name)) ~= 0;
end
end

function val = ws_get(name)
% Get variable preferring caller, else base
if evalin('caller', sprintf('exist(''%s'',''var'')', name))
    val = evalin('caller', name);
else
    val = evalin('base', name);
end
end
