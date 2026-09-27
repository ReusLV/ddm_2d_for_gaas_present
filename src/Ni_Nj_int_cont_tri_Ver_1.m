function [ce]=Ni_Nj_int_cont_tri_Ver_1(xt,yt)
% Mass matrix calculation for 2D triangular element
% Integral: ∫(Ni*Nj)dA
% Input:
% xt(3) - x coordinates of three nodes
% yt(3) - y coordinates of three nodes
% Output:
% ce(3,3) - element mass matrix

% Initialize 3x3 matrix
ce = zeros(3,3);

% Calculate element area
A = 0.5 * abs(det([1, xt(1), yt(1); 1, xt(2), yt(2); 1, xt(3), yt(3)]));

% For linear triangular elements, the mass matrix is A/12 * [2 1 1; 1 2 1; 1 1 2]
ce = A/12 * [2 1 1; 1 2 1; 1 1 2];

return; 