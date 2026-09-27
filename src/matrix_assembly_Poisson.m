% Poisson Solver 2-D
% Matrix Assembly

F1=sparse(Nnode,Nnode);
F2=sparse(Nnode,Nnode);
F3=zeros(Nnode,1);
F4x=sparse(Nnode,Nnode);
F4y=sparse(Nnode,Nnode);
S1n=sparse(Nnode,Nnode);
S0n=sparse(Nnode,1);
S1p=sparse(Nnode,Nnode);
S0p=sparse(Nnode,1);

tol = 1e-8; % tolerance for coordinate comparison
for i=1:Nel
    nds_ = el_2d_no(i,:);
    xl = [x_coords(nds_)];
    yl = [y_coords(nds_)];

    % === domain integration ===
    ae = dNi_dNj_int_cont_tri_Ver_1(xl, yl);
    be = Ni_int_cont_tri_Ver_1(xl, yl);
    ce = Ni_Nj_int_cont_tri_Ver_1(xl, yl);
    dex = dNi_Nj_int_cont_tri_Ver_1(xl, yl, 'x');
    dey = dNi_Nj_int_cont_tri_Ver_1(xl, yl, 'y');

    F1(nds_, nds_) = F1(nds_, nds_) + ae;
    F2(nds_, nds_) = F2(nds_, nds_) + ce;
    F3(nds_)       = F3(nds_)       + be;
    F4x(nds_, nds_)= F4x(nds_, nds_) + dex;
    F4y(nds_, nds_)= F4y(nds_, nds_) + dey;

    % === edge integration ===
    for edge = [1 2; 2 3; 3 1]'
        idx1 = edge(1); idx2 = edge(2);
        x1 = xl(idx1); y1 = yl(idx1);
        x2 = xl(idx2); y2 = yl(idx2);

        if abs(y1 - (H1 + H2)) < tol && abs(y2 - (H1 + H2)) < tol && ...
           x1 >= e_start - tol && x1 <= e_end + tol && ...
           x2 >= e_start - tol && x2 <= e_end + tol

            se  = Ni_Nj_int_edge([x1, x2], [y1, y2]);
            se0 = Ni_int_edge([x1, x2], [y1, y2]);

            nds_edge = [nds_(idx1), nds_(idx2)];
            S1n(nds_edge, nds_edge) = S1n(nds_edge, nds_edge) + (vsn) * se;
            S0n(nds_edge)           = S0n(nds_edge) + (vsn) * n_sc .* se0(:);

            S1p(nds_edge, nds_edge) = S1p(nds_edge, nds_edge) + (vsp) * se;
            S0p(nds_edge)           = S0p(nds_edge) + (vsp) * p_sc .* se0(:);
            % S1n(nds_edge, nds_edge) = S1n(nds_edge, nds_edge) + se;
            % S0n(nds_edge)           = S0n(nds_edge) + se0;
            % S1p(nds_edge, nds_edge) = S1p(nds_edge, nds_edge) + se;
            % S0p(nds_edge)           = S0p(nds_edge) + se0;
        end
    end
end

