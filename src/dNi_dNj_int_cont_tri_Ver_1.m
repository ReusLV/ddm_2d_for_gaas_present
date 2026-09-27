function [ae]=dNi_dNj_int_cont_tri_Ver_1(xt,yt)
% Stiffness matrix calculation for 2D triangular element
% Integral: ∫(∇Ni·∇Nj)dA
% Input:
% xt(3) - x coordinates of three nodes
% yt(3) - y coordinates of three nodes
% Output:
% ae(3,3) - element stiffness matrix

% Initialize 3x3 matrix
ae = zeros(3,3);

% Calculate element area
A = 0.5 * abs(det([1, xt(1), yt(1); 1, xt(2), yt(2); 1, xt(3), yt(3)]));

% Calculate Jacobian matrix
J = [xt(2)-xt(1), xt(3)-xt(1); yt(2)-yt(1), yt(3)-yt(1)];
J_invT = (J\eye(2))';
% J_inv = inv(J);
% detJ = det(J);

% Shape function derivatives in natural coordinates
dN_dxi = [-1, 1, 0; -1, 0, 1];  % [∂N/∂ξ; ∂N/∂η], constant over the element
            
% Transform derivatives to physical coordinates
grad_Ni = J_invT * dN_dxi;  % [∂N/∂x; ∂N/∂y]

% One point integration
% Actually the amount of integration points is not important for linear triangle
% because the derivatives are constant over the element
ae = A * (grad_Ni' * grad_Ni); % 3*2 x 2*3 = 3*3

return;