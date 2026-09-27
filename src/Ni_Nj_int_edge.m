
function se = Ni_Nj_int_edge(xl, yl)
% Ni_Nj_int_edge - Integrate shape functions Ni*Nj over a boundary edge element: ∫ Ni Nj dS
% Inputs:
%   xl, yl : coordinates of the 2 nodes (1x2 vectors)
% Output:
%   se : 2x2 matrix, each entry is ∫ Ni Nj dS


    % Length of the edge element
    dx = xl(2) - xl(1);
    dy = yl(2) - yl(1);
    L = sqrt(dx^2 + dy^2);

    se = (L/6) * [2 1; 1 2];
    
    % % Gaussian quadrature (2-point rule)
    % gp = [-1/sqrt(3), 1/sqrt(3)]; % Gauss points in reference space [-1,1]
    % w  = [1, 1];                  % Weights


    % se = zeros(2,2);
    % for k=1:2
    %     xi = gp(k);  % Reference coordinate [-1,1]
    %     Ni = [(1-xi)/2, (1+xi)/2];  % Linear shape functions
    %     se = se + (Ni'*Ni) * w(k) * (L/2);
    % end
end
