function comparison(quantity,Ubias,comsolregion)
% comparison — Minimal overlay of COMSOL cutline with current MATLAB simulation (phi/E/n) in physical units
% Usage:
%   comparison('n')  or  comparison('phi')  or  comparison('E')
%   If omitted, falls back to base variable `quantity` or defaults to 'phi'.
% Prerequisites in base workspace: phi, Eabs, n_t, x_coords, y_coords, Vt, Lo, n_i

	% ===== Minimal configuration (edit as needed) =====
	% Cutline: vertical ('y': x = const) or horizontal ('x': y = const)
	cut_dir      = 'y';          % 'y' (vertical) or 'x' (horizontal)
	cut_coord_cm = 4e-4;         % position in cm

	% COMSOL data source: either give a direct file path, or auto-build by region+bias+quantity
	comsolFile   = '';           % direct path, or leave empty to use comsol_reference/
	% Optional args with defaults
	comsolRegion = 'Vjunc';      % when auto
	Ubias_V      = 0.5;          % when auto
	if nargin>=2 && ~isempty(Ubias),        Ubias_V = Ubias;        end
	if nargin>=3 && ~isempty(comsolregion), comsolRegion = comsolregion; end

	% ===== Detect quantity to compare (phi/E/n) =====
	if nargin >= 1 && ~isempty(quantity)
		q_in = quantity;
	elseif evalin('base','exist(''quantity'',''var'')')
		q_in = evalin('base','quantity');
	else
		q_in = 'phi';
	end
	% Normalize to lowercase char and validate against allowed set
	quantity = lower(char(string(q_in)));
	if ~any(strcmp(quantity, {'phi','e','n'}))
		quantity = 'phi';
	end

	% If bias and region exist in base workspace, use them
	if evalin('base','exist(''Ubias_V'',''var'')')
		Ubias_V = evalin('base','Ubias_V');
	elseif evalin('base','exist(''Ubias'',''var'')')
		Ubias_V = evalin('base','Ubias');
	end
	if evalin('base','exist(''comsolRegion'',''var'')')
		comsolRegion = evalin('base','comsolRegion');
	end

	% ===== Auto-pick cutline by region =====
	% Rules:
	%  Vjunc -> x = 4e-4 cm (vertical)
	%  Vl    -> x = 2e-4 cm (vertical)
	%  Vr    -> x = 15.2e-4 cm (vertical)
	%  Hn    -> y = 2.05e-4 cm (horizontal)
	%  Hnn   -> y = 1e-4 cm (horizontal)
	reg = lower(strtrim(char(string(comsolRegion))));
	switch reg
		case 'vjunc'
			cut_dir = 'y';
			cut_coord_cm = 4e-4;
		case 'vl'
			cut_dir = 'y';
			cut_coord_cm = 2e-4;
		case 'vr'
			cut_dir = 'y';
			cut_coord_cm = 15.2e-4;
		case 'hn'
			cut_dir = 'x';
			cut_coord_cm = 2.05e-4;
		case 'hnn'
			cut_dir = 'x';
			cut_coord_cm = 1e-4;
		otherwise
			% keep defaults
	end

	% ===== Fetch simulation data and convert to physical units =====
	req = {'phi','Eabs','n_t','x_coords','y_coords','Vt','Lo','n_i'};
	for k=1:numel(req)
		if ~evalin('base', sprintf('exist(''%s'',''var'')', req{k}))
			error('Missing variable %s in base workspace. Run the simulation first.', req{k});
		end
	end

	phi      = evalin('base','phi');
	Eabs     = evalin('base','Eabs');
	n_t      = evalin('base','n_t');
	x_coords = evalin('base','x_coords');
	y_coords = evalin('base','y_coords');
	Vt       = evalin('base','Vt');
	Lo       = evalin('base','Lo');
	n_i      = evalin('base','n_i');

	phi_phys = phi * Vt;          % V
	E_phys   = (Vt/Lo) * Eabs;    % V/cm
	n_phys   = n_t * n_i;         % cm^-3
	x_phys   = x_coords * Lo;     % cm
	y_phys   = y_coords * Lo;     % cm

	switch quantity
		case 'phi'
			q_sim_all = phi_phys; y_label = 'Potential (V)'; baseName = 'phi';
		case 'e'
			q_sim_all = E_phys;   y_label = '|E| (V/cm)';   baseName = 'E';
		case 'n'
			q_sim_all = n_phys;   y_label = 'n (cm^{-3})';  baseName = 'logn'; % COMSOL often exports log10(n)
	end

	% Extract cutline from simulation
	[axis_sim, q_sim] = i_extract_cutline(x_phys, y_phys, q_sim_all, cut_dir, cut_coord_cm, 200);

	% ===== Find and read COMSOL cutline =====
	if isempty(comsolFile)
		% Choose suffix by contact type: SO for Schottky-Ohmic, OO for Ohmic-Ohmic when schottky==0
		suffix = 'SO';
		try
			if evalin('base','exist(''schottky'',''var'') && isequal(schottky,0)')
				suffix = 'OO';
			end
		catch
			% ignore, keep default 'SO'
		end
		fname = sprintf('%s-%.1fV-%s.txt', baseName, Ubias_V, suffix);
		projectRoot = fileparts(fileparts(mfilename('fullpath')));
		comsolFile = fullfile(projectRoot, 'comsol_reference', 'cutline', comsolRegion, fname);
	end

	% Allow looking one folder up as a fallback; also try the alternative suffix (SO<->OO) if not found
	candidates = {comsolFile, fullfile('..', comsolFile)};
	% Try alternate suffix automatically for robustness
	[comsolDir, comsolName, comsolExt] = fileparts(comsolFile);
	if contains(comsolName,'-SO')
		altName = strrep(comsolName,'-SO','-OO');
		candidates{end+1} = fullfile(comsolDir, [altName comsolExt]);
		candidates{end+1} = fullfile('..', comsolDir, [altName comsolExt]);
	elseif contains(comsolName,'-OO')
		altName = strrep(comsolName,'-OO','-SO');
		candidates{end+1} = fullfile(comsolDir, [altName comsolExt]);
		candidates{end+1} = fullfile('..', comsolDir, [altName comsolExt]);
	end
	fileFound = '';
	for i=1:numel(candidates)
		if exist(candidates{i}, 'file')
			fileFound = candidates{i};
			break;
		end
	end
	if isempty(fileFound)
		error('COMSOL file not found: %s (also tried parent path).', comsolFile);
	end

	[axis_ref_cm, data_ref, ref_is_log] = i_read_comsol_cut(fileFound);

	% Units alignment for carrier density: COMSOL often exports n in m^-3, simulation here uses cm^-3
	% Convert COMSOL reference to cm^-3 or corresponding log units
	ref_name = lower(fileFound);
	is_log10_ref = contains(ref_name,'log10');

	% ===== Simple overlay (no metrics) =====
	use_semilogy = false;
	if strcmp(quantity,'n')
		% New behavior (2025-10-08): Always plot carrier density in linear physical units (cm^-3)
		% even if the COMSOL file stores log data. Then use a logarithmic y-axis for visualization.
		% q_sim currently holds n_phys along the extracted cut (already cm^-3).
		q_sim_plot = q_sim;
		if ref_is_log
			if is_log10_ref
				% COMSOL file stores log10(n [m^-3]) -> recover n [cm^-3]
				n_ref_cm3 = 10.^data_ref / 1e6; % m^-3 -> cm^-3
			else
				% COMSOL file stores ln(n [m^-3]) -> recover n [cm^-3]
				n_ref_cm3 = exp(data_ref) / 1e6;  % m^-3 -> cm^-3
			end
			data_ref = n_ref_cm3;
		else
			% Linear data already (assumed n [m^-3]) => convert to cm^-3
			data_ref = data_ref * 1e-6;
		end
		% Apply a small floor to avoid zero on semilog plot
		min_floor = 1e-2; % adjust if needed
		q_sim_plot = max(q_sim_plot, min_floor);
		data_ref   = max(data_ref,   min_floor);
		use_semilogy = true;
		y_label = 'n (cm^{-3})';
	else
		q_sim_plot = q_sim; % phi or E
	end

	figure('Name','COMSOL vs Simulation');
	if use_semilogy
		semilogy(axis_sim, q_sim_plot, 'b-','LineWidth',1.6); hold on;
		semilogy(axis_ref_cm, data_ref, 'r--','LineWidth',1.6);
	else
		% plot(axis_sim(2:end), q_sim_plot(2:end)-q_sim_plot(1:end-1), 'b-','LineWidth',1.6); hold on;
		% plot(axis_ref_cm(2:end), data_ref(2:end)-data_ref(1:end-1), 'r--','LineWidth',1.6);
		plot(axis_sim, q_sim_plot, 'b-','LineWidth',1.6); hold on;
		plot(axis_ref_cm, data_ref, 'r--','LineWidth',1.6);
	end
	grid on;
	if lower(cut_dir)=='y'
		xlabel('y (cm)');
	else
		xlabel('x (cm)');
	end
	ylabel(y_label);
	legend('Simulation','COMSOL','Location','best');
	% Intentionally no title on the figure to keep the view clean.

	% ===== Make Y-axis range broader to avoid over-emphasizing tiny gaps =====
	try
		if use_semilogy
			% For semilog-y: use multiplicative padding
			ystack = [q_sim_plot(:); data_ref(:)];
			ystack = ystack(isfinite(ystack) & ystack > 0);
			if ~isempty(ystack)
				minp = min(ystack);
				maxp = max(ystack);
				if minp > 0 && maxp > 0
					low  = minp/3;     % expand down by ~3x
					high = maxp*1.5;   % expand up by 50%
					if low < high && isfinite(low) && isfinite(high)
						ylim([low, high]);
					end
				end
			end
		else
			% Linear y: use additive padding combining range and absolute level
			ystack = [q_sim_plot(:); data_ref(:)];
			ystack = ystack(isfinite(ystack));
			if ~isempty(ystack)
				ymin = min(ystack);
				ymax = max(ystack);
				span = ymax - ymin;
				absmax = max(abs(ymin), abs(ymax));
				pad = max([0.2*span, 0.1*absmax, 1e-12]); % broaden both sides
				low  = ymin - pad;
				high = ymax + pad;
				if low < high && isfinite(low) && isfinite(high)
					ylim([low, high]);
				end
			end
		end
	catch
		% Keep MATLAB autoscaling if anything unexpected happens
	end

	% ===== Auto-save figure (guarded by save switch) =====
	% Only save when base workspace has variable `save_figs` equal to 1
	try
		do_save = evalin('base','exist(''save_figs'',''var'') && isequal(save_figs,1)');
	catch
		do_save = false;
	end
	if do_save
		% Save under results/comparisons, named by voltage, contact type, and quantity.
		% Contact type: SO (Schottky-Ohmic) by default; OO (Ohmic-Ohmic) when schottky==0
		contactSuffix = 'SO';
		try
			if evalin('base','exist(''schottky'',''var'') && isequal(schottky,0)')
				contactSuffix = 'OO';
			end
		catch
			% keep default
		end
		% If the found COMSOL file explicitly carries the suffix, honor it
		if contains(upper(fileFound), '-OO')
			contactSuffix = 'OO';
		elseif contains(upper(fileFound), '-SO')
			contactSuffix = 'SO';
		end

		projectRoot = fileparts(fileparts(mfilename('fullpath')));
		compDir = fullfile(projectRoot, 'results', 'comparisons');
		if ~exist(compDir, 'dir'), mkdir(compDir); end
		% Append cutline position (use micrometers for readability)
		dirChar = lower(cut_dir(1));
		pos_um  = cut_coord_cm * 1e4; % cm -> um
		fileBase = sprintf('%.2fV_%s_%s_%s%.3fum', Ubias_V, contactSuffix, lower(quantity), dirChar, pos_um);
		pngPath  = fullfile(compDir, [fileBase '.png']);
		try
			if exist('exportgraphics','file')
				exportgraphics(gcf, pngPath, 'Resolution', 300);
			else
				saveas(gcf, pngPath);
			end
			fprintf('Saved comparison figure to: %s\n', pngPath);
		catch ME
			% Use identifier + format to satisfy linters
			warning('comparison:SaveFailed', 'Failed to save figure: %s', ME.message);
		end
	else
		% fprintf('Save switch disabled: figure not saved.\n');
	end

end

%% ===== Local helpers =====
function [axis_vals_cm, q_cut] = i_extract_cutline(x_cm, y_cm, q_all, cut_dir, cut_coord_cm, n_samples)
	if nargin<6, n_samples=100; end
	F = scatteredInterpolant(x_cm(:), y_cm(:), q_all(:), 'linear', 'none');
	cd_lower = lower(cut_dir);
	switch cd_lower
		case 'y'  % vertical: x = const
            if cut_coord_cm < 15e-4
			    axis_vals_cm = linspace(0, 2.1e-4, n_samples).';
            else
                axis_vals_cm = linspace(0, 2e-4, n_samples).';
            end
			xq = cut_coord_cm * ones(size(axis_vals_cm));
			yq = axis_vals_cm;
		case 'x'  % horizontal: y = const
            if cut_coord_cm < 2e-4
			    axis_vals_cm = linspace(0,25e-4, n_samples).';
            else
                axis_vals_cm = linspace(0,15e-4, n_samples).';
            end
			xq = axis_vals_cm;
			yq = cut_coord_cm * ones(size(axis_vals_cm));
		otherwise
			error('cut_dir must be ''x'' or ''y''');
	end
	q_cut = F(xq, yq);
end

function [coord_cm, data_val, is_log] = i_read_comsol_cut(filePath)
	% Simple reader: assumes first two numeric columns; first is arc length in µm
	% Scale first column µm -> cm, detect log by filename containing 'log'
	M = readmatrix(filePath);
	if isempty(M) || size(M,2) < 2
		error('Cannot read COMSOL file: %s', filePath);
	end
	coord_cm = M(:,1) * 1e-4; % assume arc length in µm
	data_val = M(:,2);
	[~, fname, ~] = fileparts(filePath);
	is_log = contains(lower(fname), 'log');
end


