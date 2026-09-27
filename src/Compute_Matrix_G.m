function [G1]=Compute_Matrix_G(dphi_dx, dphi_dy, x_coords, y_coords, el_2d_no)
    % Compute Matrix G of the drift-diffusion solver for 2D triangular elements
    % Input: 
    % dphi_dx(Ne_2d,1) - x derivatives of the potential at each element
    % dphi_dy(Ne_2d,1) - y derivatives of the potential at each element
    % x_coords(Nn,1) - normalized x coordinates of the nodes
    % y_coords(Nn,1) - normalized y coordinates of the nodes
    % el_2d_no(Ne_2d,3) - nodes of each triangular element
    % Output: G1(Nn,Nn)
    
    [Nn,~]=size(x_coords);
    [Ne_2d,~]=size(el_2d_no);
    
    G1=sparse(Nn,Nn);
    
    for i=1:Ne_2d % Loop over 2-D triangular elements
        nds_=el_2d_no(i,1:3);
        xl=[x_coords(nds_(1)),x_coords(nds_(2)),x_coords(nds_(3))];
        yl=[y_coords(nds_(1)),y_coords(nds_(2)),y_coords(nds_(3))];
            
        % Calculate matrices containing contributions from x and y directional derivatives
        de_x = dNi_Nj_int_cont_tri_Ver_1(xl, yl, 'x') * dphi_dx(i);
        de_y = dNi_Nj_int_cont_tri_Ver_1(xl, yl, 'y') * dphi_dy(i);
        
        % Combine contributions from both directions
        de = de_x + de_y;
        
        G1(nds_,nds_)=G1(nds_,nds_)+de;
        
    end % End of Loop over 2-D elements
    