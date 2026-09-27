function diagnostics_ddm(K, name)
%DIAGNOSTICS_DDM  Basic structural diagnostics for linear system matrices.
%   Prints off-diagonal sign statistics, diagonal dominance violations,
%   row sum extrema and a cheap condition estimate.
%
%   K: sparse matrix
%   name: string label

fprintf('\n[Diagnostics] Matrix %s\n', name);
N = size(K,1);
diagK = full(diag(K));
K_no_diag = K - spdiags(diagK,0,N,N);

% Off-diagonal stats
off_vals = nonzeros(K_no_diag);
pos_off = sum(off_vals > 1e-14);
neg_off = sum(off_vals < -1e-14);
zero_off = length(off_vals) - pos_off - neg_off;
fprintf('  Off-diagonals: pos=%d (%.2f%%)  neg=%d (%.2f%%)  near-zero=%d\n', ...
    pos_off, 100*pos_off/max(1,length(off_vals)), ...
    neg_off, 100*neg_off/max(1,length(off_vals)), zero_off);

% Diagonal dominance (strict)
abs_off_sum = full(sum(abs(K_no_diag),2));
viol = sum(diagK < abs_off_sum - 1e-14);
fprintf('  Diagonal dominance violations: %d (%.2f%%)\n', viol, 100*viol/N);

% Row sums (M-matrix like property would expect non-positive off-diagonals & non-negative diagonal dominance)
row_sums = full(sum(K,2));
fprintf('  Row sum range: [%.3e, %.3e]  (mean=%.3e)\n', min(row_sums), max(row_sums), mean(row_sums));

% Condition number estimate (can be expensive; guard size)
try
    if N <= 2e4
        cEst = condest(K);
        fprintf('  condest(K) ~ %.3e\n', cEst);
    else
        fprintf('  condest skipped (matrix too large: N=%d)\n', N);
    end
catch ME
    fprintf('  condest failed: %s\n', ME.message);
end

% Simple positivity predictor: any row with a large positive off-diagonal sum
pos_off_sum_rows = sum(K_no_diag > 0,2);
hot_rows = find(pos_off_sum_rows > 4); %#ok<NASGU>
fprintf('  Rows with >4 positive off-diagonals: %d\n', sum(pos_off_sum_rows > 4));

fprintf('  Diag range: [%.3e, %.3e]\n', min(diagK), max(diagK));
end
