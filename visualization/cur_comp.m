function cur_comp(cur_type, Ubias, contact_type, onlyElectrode)
% cur_comp  Compare simulated top boundary top-edge current density (Jy) with COMSOL reference
% -------------------------------------------------------------------------
% Usage:
%   cur_comp(cur_type, Ubias, contact_type)
%   cur_comp(cur_type, Ubias, contact_type, onlyElectrode)
%
% Arguments:
%   cur_type      : 'drift' | 'diff'   (only these two are supported now)
%   Ubias         : Applied device bias (V) (used for informative print & default reference name)
%   contact_type  : Contact identifier (e.g. 'OO', 'Hn', 'Hnn') used in naming
%   onlyElectrode : (optional bool, default=true) if true restrict x to [e_start,e_end]; if false use entire top boundary
%
% Reference file path is auto-constructed; no manual ref_file argument needed.
%
% Expected reference file format (CSV / TXT):
%   Column 1: x coordinate (cm)
%   Column 2: J_y current density (A/cm^2), positive toward +y
%   If only one column present it is interpreted as an average J_y value
%
% Default COMSOL reference filename pattern adopted here:
%   comsol_reference/cutline/top_electrode/JdriftY-<Ubias>V-<contact_type>.txt
%   comsol_reference/cutline/top_electrode/JdiffY-<Ubias>V-<contact_type>.txt
% Ubias is formatted with up to one decimal place (e.g., 0.5 -> '0.5').
%
% Output: prints statistics and produces comparison plots (if reference present)
%
% Dependencies: assumes these variables already exist in base workspace when called
%   el_2d_no, x_coords, y_coords, Lo, Jo,
%   jy_nt, jy_pt,
%   jy_drift_nt, jy_drift_pt,
%   jy_diff_nt,  jy_diff_pt,
%   count2 (index of last stored time step)
%
% Author: auto-generated (GitHub Copilot)
% -------------------------------------------------------------------------

if nargin < 4 || isempty(onlyElectrode)
    onlyElectrode = true; % default restrict to electrode window
end

ws_vars = evalin('base','who');
required_arrays = { ...
    'el_2d_no','x_coords','y_coords','Jo','Lo','count2', ...
    'jy_nt','jy_pt','jy_drift_nt','jy_drift_pt','jy_diff_nt','jy_diff_pt'}; %#ok<*NASGU>

missing = setdiff(required_arrays, ws_vars);
if ~isempty(missing)
    error('cur_comp:MissingVars','Missing variables in base workspace: %s', strjoin(missing,', '));
end

% Fetch required variables
el_2d_no    = evalin('base','el_2d_no');
x_coords    = evalin('base','x_coords');
y_coords    = evalin('base','y_coords');
Jo          = evalin('base','Jo');     % Normalization current density scale (A/cm^2)
Lo          = evalin('base','Lo');     % Normalization length (cm)
count2      = evalin('base','count2'); % Last stored time step index

jy_nt       = evalin('base','jy_nt');      % (Nel, Ns) electrons total
jy_pt       = evalin('base','jy_pt');      % (Nel, Ns) holes total
jy_drift_nt = evalin('base','jy_drift_nt');
jy_drift_pt = evalin('base','jy_drift_pt');
jy_diff_nt  = evalin('base','jy_diff_nt');
jy_diff_pt  = evalin('base','jy_diff_pt');

if count2 < 1
    error('cur_comp:NoData','No stored time step (count2 < 1). Call after simulation time loop.');
end

% Interpret current type
cur_type = lower(strtrim(cur_type));
switch cur_type
    case 'drift'
        Jy_e_dimless = jy_drift_nt(:,count2); % electron drift component
        Jy_h_dimless = jy_drift_pt(:,count2); % hole drift component
        legend_tag_sim = 'Sim Drift (e+h)'; %#ok<NASGU>
    case 'diff'
        Jy_e_dimless = jy_diff_nt(:,count2);
        Jy_h_dimless = jy_diff_pt(:,count2);
        legend_tag_sim = 'Sim Diff (e+h)'; %#ok<NASGU>
    otherwise
        error('cur_comp:BadType','Unsupported cur_type = %s (use ''drift'' or ''diff'')', cur_type);
end

Jy_dimless = Jy_e_dimless + Jy_h_dimless;          % dimensionless (relative to Jo)
Jy_phys    = Jy_dimless * Jo;                      % A/cm^2

% --- Identify top contact elements robustly (edge-based) ---
Nel = size(el_2d_no,1);

% Try to fetch geometry/contact window variables
H1 = []; H2 = []; e_start = []; e_end = []; tol = 1e-8; % defaults / placeholders
fetch_list = {'H1','H2','e_start','e_end','tol'};
for k=1:numel(fetch_list)
    nm = fetch_list{k};
    try
        if evalin('base', sprintf('exist(''%s'',''var'')', nm))
            eval(sprintf('%s = evalin(''base'',''%s'');', nm, nm)); %#ok<EVLDIR>
        end
    catch
        % ignore errors, keep defaults
    end
end

% y-coordinate of physical (normalized) top boundary
if exist('H1','var') && ~isempty(H1) && exist('H2','var') && ~isempty(H2)
    y_top_line = H1 + H2;
else
    y_top_line = max(y_coords(:)); % fallback
end

% Primary detection: element has at least one horizontal edge fully on top line within electrode window
idx_top = [];
top_mask = false(Nel,1);
if onlyElectrode && ~isempty(e_start) && ~isempty(e_end)
    use_window = true;
else
    use_window = false; % take full top boundary
    e_start = -inf; e_end = inf; %#ok<*NASGU>
end

% Build edges for triangle (generalize if needed)
node_per_elem = size(el_2d_no,2);
if node_per_elem == 3
    edge_pairs = [1 2; 2 3; 3 1];
else
    % Generic all unique unordered pairs
    tmp = nchoosek(1:node_per_elem,2); edge_pairs = tmp; %#ok<NASGU>
end

% Use local tolerance candidate
tol_primary = max( tol, 1e-8 );

for e=1:Nel
    nodes = el_2d_no(e,:);
    ye = y_coords(nodes);
    xe = x_coords(nodes);
    for ep = 1:size(edge_pairs,1)
        i1 = edge_pairs(ep,1); i2 = edge_pairs(ep,2);
        y1 = ye(i1); y2 = ye(i2);
        x1 = xe(i1); x2 = xe(i2);
        if abs(y1 - y_top_line) < tol_primary && abs(y2 - y_top_line) < tol_primary
            if ~use_window || (x1 >= e_start - tol_primary && x1 <= e_end + tol_primary && ...
                               x2 >= e_start - tol_primary && x2 <= e_end + tol_primary)
                top_mask(e) = true; break; %#ok<BRKOUT>
            end
        end
    end
end

idx_top = find(top_mask);

% Secondary fallback: loosen tolerance if none found
if isempty(idx_top)
    tol_loose = max(tol_primary*10, 1e-7);
    for e=1:Nel
        nodes = el_2d_no(e,:);
        ye = y_coords(nodes); xe = x_coords(nodes);
        for ep=1:size(edge_pairs,1)
            i1=edge_pairs(ep,1); i2=edge_pairs(ep,2);
            y1=ye(i1); y2=ye(i2); x1=xe(i1); x2=xe(i2);
            if abs(y1 - y_top_line) < tol_loose && abs(y2 - y_top_line) < tol_loose
                if ~use_window || (x1 >= e_start - tol_loose && x1 <= e_end + tol_loose && ...
                                   x2 >= e_start - tol_loose && x2 <= e_end + tol_loose)
                    top_mask(e)=true; break;
                end
            end
        end
    end
    idx_top = find(top_mask);
    if isempty(idx_top)
        % Final fallback: original y_max heuristic
        all_node_y = y_coords(:); y_max = max(all_node_y);
        Y_elem_nodes = y_coords(el_2d_no);
        abs_tol = max(1e-8, 1e-6 * y_max);
        is_top_elem = all( (y_max - Y_elem_nodes) <= abs_tol , 2);
        idx_top = find(is_top_elem);
        if isempty(idx_top)
            fprintf(['[cur_comp] WARNING: No top elements detected. Debug info:\n' ...
                     '  y_top_line=%.6g, y_max(nodes)=%.6g, tol=%.3g, tol_loose=%.3g\n'], ...
                     y_top_line, y_max, tol_primary, tol_loose);
            sample_y = sort(unique(y_coords));
            sample_tail = sample_y(end-min(10,numel(sample_y))+1:end);
            fprintf('  Highest y node values: %s\n', mat2str(sample_tail,6));
        end
    end
end

if isempty(idx_top)
    % Graceful exit avoiding NaNs
    fprintf('[cur_comp] No top contact elements found; aborting comparison.\n');
    return;
end

Jy_top = Jy_phys(idx_top);

% Element centers (x) for those elements (cm)
X_elem_nodes = x_coords(el_2d_no(idx_top,:));
x_top = mean(X_elem_nodes,2) * Lo;

% Sort for plotting
[x_top, order] = sort(x_top);
Jy_top = Jy_top(order);

% Statistics
Jy_mean = mean(Jy_top);
Jy_min  = min(Jy_top);
Jy_max  = max(Jy_top);
Jy_std  = std(Jy_top);

fprintf('\n==== cur_comp results ====');
fprintf('\nBias Ubias = %.4g V, contact = %s, current type = %s, onlyElectrode=%d', Ubias, contact_type, cur_type, onlyElectrode);
fprintf('\nNumber of top elements: %d', numel(idx_top));
fprintf('\nJy physical (A/cm^2): mean=%.4e, min=%.4e, max=%.4e, std=%.4e\n', Jy_mean, Jy_min, Jy_max, Jy_std);

% Auto-build reference file path (COMSOL cutline naming)
% Reference exports consistently use one decimal place (for example, 0.0V).
Ubias_str = sprintf('%.1f', Ubias);
switch cur_type
    case 'drift'
        ref_filename = sprintf('JdriftY-%sV-%s.txt', Ubias_str, contact_type);
    case 'diff'
        ref_filename = sprintf('JdiffY-%sV-%s.txt', Ubias_str, contact_type);
    otherwise
        error('Unexpected cur_type after validation');
end
projectRoot = fileparts(fileparts(mfilename('fullpath')));
ref_file = fullfile(projectRoot, 'comsol_reference', 'cutline', ...
    'top_electrode', ref_filename);
if ~exist(ref_file,'file')
    fprintf('Reference file not found at %s. Proceeding without reference.\n', ref_file);
end

ref_exists = exist(ref_file,'file') == 2;
ref_loaded = false;
ref_x = []; ref_J = [];
if ref_exists
    try
        % Manual parsing to skip header lines starting with '%'
        fid = fopen(ref_file,'r');
        if fid < 0
            warning('Could not open reference file %s for reading.', ref_file);
        else
            numeric_data = [];
            while true
                ln = fgetl(fid);
                if ~ischar(ln); break; end
                s = strtrim(ln);
                if isempty(s) || startsWith(s,'%'); continue; end
                % Tokenize line; expect first token: arc length (µm), second: Jy (A/cm^2)
                parts = regexp(s,'\s+','split');
                if numel(parts) >= 2
                    a = str2double(parts{1});
                    b = str2double(parts{2});
                    if ~isnan(a) && ~isnan(b)
                        numeric_data(end+1,1:2) = [a,b]; %#ok<AGROW>
                    end
                end
            end
            fclose(fid);
            if isempty(numeric_data)
                warning('Reference file %s contained no numeric data after header skip.', ref_file);
            else
                % Convert arc length µm -> cm (1 µm = 1e-4 cm)
                ref_x = numeric_data(:,1) * 1e-4; % cm
                ref_J = numeric_data(:,2);        % A/cm^2
                ref_loaded = true;
            end
        end
    catch ME
        warning('Failed to parse reference file (%s): %s', ref_file, ME.message);
    end
else
    fprintf('Reference file not found: %s (simulation only)\n', ref_file);
end

if ref_loaded && numel(ref_J) > 1 && ~isempty(ref_x)
    % Raw overlay: no interpolation; each dataset keeps its own x sampling
    [ref_x, iu] = unique(ref_x(:)); ref_J = ref_J(iu);
    % If onlyElectrode mode and electrode window known, clip reference range
    if exist('onlyElectrode','var') && onlyElectrode && exist('use_window','var') && use_window ...
            && ~isinf(e_start) && ~isinf(e_end)
        % Convert electrode window (normalized) to physical cm
        e_start_cm = e_start * Lo; e_end_cm = e_end * Lo;
        ref_mask = ref_x >= e_start_cm - 1e-12 & ref_x <= e_end_cm + 1e-12;
        if any(ref_mask)
            ref_x = ref_x(ref_mask);
            ref_J = ref_J(ref_mask);
        else
            fprintf('[cur_comp] WARNING: Reference data has no points within electrode window [%.4e, %.4e] cm. Using full reference range.\n', e_start_cm, e_end_cm);
        end
    end
    figure('Name','cur_comp raw comparison','Color','w');
    plot(ref_x*1e4, ref_J, 'k--','LineWidth',1.1); hold on; % ref x (cm) -> µm
    plot(x_top*1e4, Jy_top, 'b-o','LineWidth',1.3, 'MarkerSize',4);
    xlabel('x (µm)'); ylabel('J_y (A/cm^2)');
    title(sprintf('Top Boundary J_y Raw Comparison (%s, %s, %.3g V)', contact_type, cur_type, Ubias));
    legend('COMSOL raw','Simulation','Location','best'); grid on;
    % Basic scalar stats for context
    ref_mean = mean(ref_J); sim_mean = Jy_mean; ratio = sim_mean / max(1e-30, ref_mean);
    fprintf('Ref mean = %.4e, Sim mean = %.4e, Sim/Ref = %.3f\n', ref_mean, sim_mean, ratio);
elseif ref_loaded && numel(ref_J) >= 1
    % Only average number present
    ref_mean = mean(ref_J); diff_mean = Jy_mean - ref_mean; rel_err = diff_mean / max(1e-30, abs(ref_mean));
    fprintf('Reference mean J = %.4e A/cm^2, Simulation mean J = %.4e A/cm^2, Diff = %.4e (%.2f%%)\n', ...
        ref_mean, Jy_mean, diff_mean, rel_err*100);
    figure('Name','cur_comp average compare','Color','w');
    bar([ref_mean, Jy_mean]); set(gca,'XTickLabel',{'COMSOL','Simulation'});
    ylabel('Average J_y (A/cm^2)'); title(sprintf('Average J_y (%s, %s, %.3g V)', contact_type, cur_type, Ubias)); grid on;
else
    figure('Name','cur_comp simulation only','Color','w');
    plot(x_top*1e4, Jy_top, 'b-o','LineWidth',1.5); xlabel('x (µm)'); ylabel('J_y (A/cm^2)');
    title(sprintf('Top Boundary J_y Simulation (%s, %s, %.3g V)', contact_type, cur_type, Ubias)); grid on;
end

% Optional: list each top element
if numel(idx_top) <= 200
    T = table(x_top(:), Jy_top(:), 'VariableNames', {'x_cm','J_y_A_per_cm2'});
    disp(T);
else
    fprintf('Too many top elements (%d), omitting per-element list.\n', numel(idx_top));
end

end % function cur_comp
