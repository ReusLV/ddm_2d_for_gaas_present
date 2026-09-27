function [be]=Ni_int_cont_tri_Ver_1(xt,yt)
% Load vector calculation for 2D triangular element
% Integral: ∫(Ni)dA
% Input:
% xt(3) - x coordinates of three nodes
% yt(3) - y coordinates of three nodes
% Output:
% be(3,1) - element load vector

% Initialize 3x1 vector
be = zeros(3,1);

% Calculate element area
A = 0.5 * abs(det([1, xt(1), yt(1); 1, xt(2), yt(2); 1, xt(3), yt(3)]));

% For linear triangular elements, the integral of shape functions is A/3
be = A/3 * [1; 1; 1];

return; 