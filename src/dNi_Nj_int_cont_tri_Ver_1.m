function [de]=dNi_Nj_int_cont_tri_Ver_1(xt, yt, direction)
    % Integral contribution ∫(∇Ni * Nj) dA for 2D triangular element
    % xt(3), yt(3): coordinates of the triangle's nodes
    % direction: optional parameter, can be 'x', 'y', or omitted
    % de(3,3,2) or de(3,3): output array
    %   If direction is omitted: de(:,:,1) = ∫(∂Ni/∂x * Nj) dA, de(:,:,2) = ∫(∂Ni/∂y * Nj) dA
    %   If direction is 'x': de = ∫(∂Ni/∂x * Nj) dA
    %   If direction is 'y': de = ∫(∂Ni/∂y * Nj) dA
    
    % 1. Calculate element area
    A = 0.5 * abs(det([1, xt(1), yt(1);
                       1, xt(2), yt(2);
                       1, xt(3), yt(3)]));
    
    % 2. Jacobian matrix and its inverse
    J     = [xt(2)-xt(1), xt(3)-xt(1);
             yt(2)-yt(1), yt(3)-yt(1)];
    J_inv = inv(J);
    
    % 3. Shape function derivatives in reference coordinates
    dN_dxi = [-1,  1, 0;
              -1,  0, 1];
    
    % 4. Gradients in physical coordinates ∂N/∂x, ∂N/∂y (constants)
    grad_N = J_inv' * dN_dxi;  % 2×3
    
    % 5. ∫ N_j dA = A/3
    S = A/3;
    
    % 6. Assemble de based on direction parameter
    if nargin < 3
        % Return both x and y components if direction is not specified
        de = zeros(3,3,2);
        de(:,:,1) = S * repmat(grad_N(1,:), 3, 1);  % x component
        de(:,:,2) = S * repmat(grad_N(2,:), 3, 1);  % y component
    elseif strcmp(direction, 'x')
        % Return only x component
        de = S * repmat(grad_N(1,:), 3, 1);  % x component
    elseif strcmp(direction, 'y')
        % Return only y component
        de = S * repmat(grad_N(2,:), 3, 1);  % y component
    else
        error('Invalid direction parameter. Use ''x'', ''y'', or omit for both components.');
    end
    de=de';
end
