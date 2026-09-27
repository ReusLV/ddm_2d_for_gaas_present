function run_simulation
%RUN_SIMULATION Add project folders to the path and run the default solver.

projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));
addpath(fullfile(projectRoot, 'visualization'));

mainScript = fullfile(projectRoot, 'src', ...
    'fem_2d_Semiconductor_Transient_Analysis_Ver_2.m');
mainScript = strrep(mainScript, '''', '''''');

% The research scripts and comparison helpers share data through MATLAB's
% base workspace, so execute the driver there rather than in this function.
evalin('base', sprintf('run(''%s'')', mainScript));
end
