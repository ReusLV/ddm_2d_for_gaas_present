
function se0 = Ni_int_edge(xl, yl)
% Ni_int_edge - Integrate shape functions Ni over a boundary edge element: ∫ Ni dS
% Inputs:
%   xl, yl : coordinates of the 2 nodes (1x2 vectors)
% Output:
%   se0 : 2x1 vector, each entry is ∫ Ni dS for each node

    % Length of the edge element
    dx = xl(2) - xl(1);
    dy = yl(2) - yl(1);
    L = sqrt(dx^2 + dy^2);

    se0 = (L/2) * [1; 1];
    % % Gaussian quadrature (2-point rule)
    % gp = [-1/sqrt(3), 1/sqrt(3)]; % Gauss points in reference space [-1,1]
    % w  = [1, 1];                  % Weights

    % se0 = zeros(2,1);
    % for k=1:2
    %     xi = gp(k);  % Reference coordinate [-1,1]
    %     Ni = [(1-xi)/2, (1+xi)/2];  % Linear shape functions
    %     se0 = se0 + Ni' * w(k) * (L/2);
    % end
end
