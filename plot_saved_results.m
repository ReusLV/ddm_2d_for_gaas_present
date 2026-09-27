function plot_saved_results
%PLOT_SAVED_RESULTS Plot the committed voltage sweep without recomputing it.

projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'src'));
addpath(fullfile(projectRoot, 'visualization'));

sweepScript = fullfile(projectRoot, 'visualization', ...
    'sweep_steady_current.m');
run(sweepScript);
end
