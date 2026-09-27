function e_field_comp(varargin)
% e_field_comp  Compare electric field from two data files and plot.
% MATLAB translation of e_field_comp.py
%
% Usage (Name-Value pairs):
%   e_field_comp();
%   e_field_comp('fine','Eabs_top_electrode_fine.txt', ...
%                'efine','Eabs_top_electrode_efine.txt', ...
%                'xlabel','electrode position [\mum]', ...
%                'ylabel','|E| [V/cm]', ...
%                'title','', ...
%                'xscale','linear', 'yscale','linear', ...
%                'save','out.png', 'dpi',180, 'show',true, 'debug',true, 'logy',false);
%
% Behavior:
% - Reads two text files. Comment lines starting with # or % and blank lines are skipped.
% - If a line has one numeric value, it's treated as a single-column series.
% - If lines have multiple numeric values, the first value is X, the last value is Y.
% - If rows have varying number of values, missing trailing values are treated as NaN
%   and the last non-NaN per row is used as Y.

  % Defaults matching the Python script
  p = inputParser;
  addParameter(p,'fine','Eabs_top_electrode_fine.txt');
  addParameter(p,'efine','Eabs_top_electrode_efine.txt');
  addParameter(p,'xlabel','electrode position [\mum]');
  addParameter(p,'ylabel','|E| [V/cm]');
  addParameter(p,'title','');
  addParameter(p,'xscale','linear');   % 'linear' | 'log'
  addParameter(p,'yscale','linear');   % 'linear' | 'log'
  addParameter(p,'save','');           % output image path; empty means no save
  addParameter(p,'dpi',180);           % resolution when saving
  addParameter(p,'show',false);        % show the figure window
  addParameter(p,'debug',false);
  addParameter(p,'logy',false);        % shortcut: set Y scale to log
  parse(p,varargin{:});
  args = p.Results;

  if args.logy
    args.yscale = 'log';
  end

  % Resolve and read data
  if args.debug
    fprintf('[DEBUG] Fine file (raw): %s\n', args.fine);
    fprintf('[DEBUG] Extra fine file (raw): %s\n', args.efine);
  end

  [x1,y1] = load_numeric_table_local(args.fine);
  [x2,y2] = load_numeric_table_local(args.efine);

  if args.debug
    fprintf('[DEBUG] Loaded fine shape: x=%dx1, y=%dx1\n', numel(x1), numel(y1));
    fprintf('[DEBUG] Loaded extra fine shape: x=%dx1, y=%dx1\n', numel(x2), numel(y2));
  end

  % Colors approximating matplotlib defaults
  colFine = [0.1216 0.4667 0.7059];   % #1f77b4
  colEfine = [0.8392 0.1529 0.1569];  % #d62728

  % Create figure; if not showing, make invisible
  figVisible = 'on';
  if ~args.show && ~isempty(args.save)
    figVisible = 'off';
  end
  fig = figure('Visible',figVisible,'Color','w','Position',[100 100 640 420]);
  ax = axes('Parent',fig);
  hold(ax,'on');

  plot(ax, x1, y1, 'LineWidth', 1.6, 'Color', colFine, 'DisplayName','fine');
  plot(ax, x2, y2, 'LineWidth', 1.4, 'Color', colEfine, 'DisplayName','extra fine', 'LineStyle','-');

  xlabel(ax, args.xlabel, 'Interpreter','tex');
  ylabel(ax, args.ylabel, 'Interpreter','tex');
  title(ax, args.title, 'Interpreter','none');

  % Scales
  set(ax,'XScale', validate_scale(args.xscale));
  set(ax,'YScale', validate_scale(args.yscale));

  grid(ax,'on');
  box(ax,'on');
  legend(ax,'show','Location','best');
  set(ax,'LineWidth',0.8);
  axis(ax,'tight');

  % Save if requested
  if ~isempty(args.save)
    try
      exportgraphics(ax, args.save, 'Resolution', args.dpi, 'BackgroundColor','white');
    catch
      set(fig, 'PaperPositionMode', 'auto');
      print(fig, args.save, '-dpng', sprintf('-r%d', args.dpi));
    end
    fprintf('Saved figure: %s\n', absolute_path(args.save));
  end

  % Show or close depending on args
  if args.show || isempty(args.save)
    set(fig,'Visible','on');
    drawnow;
  else
    close(fig);
  end
end

function scale = validate_scale(s)
  if isstring(s) || ischar(s)
    s = char(lower(string(s)));
  else
    s = 'linear';
  end
  if any(strcmp(s, {'linear','log'}))
    scale = s;
  else
    scale = 'linear';
  end
end

function [x, y] = load_numeric_table_local(pathStr)
% Load numeric lines from text file; ignore blank lines and lines starting with # or %.
  if ~(ischar(pathStr) || isstring(pathStr))
    error('Path must be a char or string.');
  end
  pathStr = char(pathStr);

  % Try to resolve relative paths against common locations
  resolved = '';
  try
    scriptDir = fileparts(mfilename('fullpath'));
  catch
    scriptDir = pwd;
  end
  projectRoot = fileparts(scriptDir);
  [p0, nm, ex] = fileparts(pathStr);
  base = [nm ex];
  candidates = {};
  % If an explicit directory was given, try it as-is first
  if ~isempty(p0)
    candidates{end+1} = pathStr; %#ok<AGROW>
  end
  % Try current working directory and script directory
  candidates = [candidates, { ...
    fullfile(pwd, pathStr), ...
    fullfile(pwd, base), ...
    fullfile(scriptDir, pathStr), ...
    fullfile(scriptDir, base), ...
    fullfile(scriptDir, 'results', base), ...
    fullfile('results', base), ...
    fullfile(projectRoot, 'comsol_reference', 'cutline', base), ...
    fullfile(projectRoot, 'comsol_reference', 'cutline', 'top_electrode', base) }]; %#ok<AGROW>

  for i = 1:numel(candidates)
    if isfile(candidates{i})
      resolved = candidates{i};
      break;
    end
  end

  if isempty(resolved)
    % Final attempt: try MATLAB path resolution
    whichPath = which(base);
    if ~isempty(whichPath) && isfile(whichPath)
      resolved = whichPath;
    end
  end

  if isempty(resolved)
    % Build a readable list of attempted locations
    triedList = strjoin(cellfun(@(p)sprintf('  - %s', p), candidates, 'UniformOutput', false), sprintf('\n'));
    msg = sprintf('File not found: %s\nTried:\n%s', pathStr, triedList);
    error('e_field_comp:FileNotFound', '%s', msg);
  end

  pathStr = resolved;

  fid = fopen(pathStr,'r');
  if fid < 0
    error('Cannot open file: %s', pathStr);
  end
  cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

  rows = {};
  while true
    t = fgetl(fid);
    if ~ischar(t); break; end
    s = strtrim(t);
    if isempty(s); continue; end
    if startsWith(s,'#') || startsWith(s,'%'); continue; end
    nums = sscanf(s, '%f');
    if isempty(nums); continue; end
    rows{end+1,1} = nums(:).'; %#ok<AGROW>
  end

  if isempty(rows)
    error('No usable data in file: %s', pathStr);
  end

  % Determine max number of columns; pad with NaN
  lens = cellfun(@(r) numel(r), rows);
  maxLen = max(lens);
  if maxLen == 1
    % Single-column data: index as x (starting at 0), values as y
    y = cell2mat(rows);
    x = (0:numel(y)-1).';
    y = y(:);
    return;
  end

  N = numel(rows);
  data = nan(N, maxLen);
  for i = 1:N
    v = rows{i};
    data(i,1:numel(v)) = v;
  end

  % Multi-column: x = first column, y = last non-NaN value per row
  x = data(:,1);
  y = zeros(N,1);
  for i = 1:N
    row = data(i,:);
    idx = find(~isnan(row), 1, 'last');
    if isempty(idx)
      y(i) = NaN; %#ok<NASGU>
    else
      y(i) = row(idx);
    end
  end
end

function p = absolute_path(pathStr)
  try
    f = java.io.File(pathStr);
    p = char(f.getCanonicalPath());
  catch
    p = pathStr;
  end
end
