function [dphi_dx, dphi_dy]=compute_dphi(phi,el_2d_no,x_coords,y_coords)
% Compute gradient of the potential (d_phi/dx, d_phi/dy)
% March 6, 2019
% Input
% phi(Nn,1) - normalized potential
% el_2d_no(Ne,3) - 2D triangular element connectivity
% x_no_n(Nn,1) - normalized x nodal coordinates
% y_no_n(Nn,1) - normalized y nodal coordinates
% Output
% dphi_dx(Ne,1) - derivative of the potential d_phi/dx
% dphi_dy(Ne,1) - derivative of the potential d_phi/dy

[Ne,~]=size(el_2d_no);
Nnode = numel(x_coords);

dphi_dx=zeros(Ne,1);
dphi_dy=zeros(Ne,1);
Eabs=zeros(Ne,1);
Ssupp=zeros(Ne,1);

for i=1:Ne
    % Get the three nodes of the triangle
    no1=el_2d_no(i,1);
    no2=el_2d_no(i,2);
    no3=el_2d_no(i,3);
    
    % Get the coordinates of the three nodes
    x1=x_coords(no1); y1=y_coords(no1);
    x2=x_coords(no2); y2=y_coords(no2);
    x3=x_coords(no3); y3=y_coords(no3);
    
    % Get the potential values at the nodes
    phi1=phi(no1);
    phi2=phi(no2);
    phi3=phi(no3);
    
    % Calculate the area of the triangle
    area=0.5*abs((x2-x1)*(y3-y1)-(x3-x1)*(y2-y1));
    
    % Calculate the gradients using shape function derivatives
    b1=(y2-y3)/(2*area);
    b2=(y3-y1)/(2*area);
    b3=(y1-y2)/(2*area);
    
    c1=(x3-x2)/(2*area);
    c2=(x1-x3)/(2*area);
    c3=(x2-x1)/(2*area);
    
    % Calculate the derivatives
    dphidx=b1*phi1+b2*phi2+b3*phi3;
    dphidy=c1*phi1+c2*phi2+c3*phi3;

    dphi_dx(no1)=dphi_dx(no1)+area*dphidx;
    dphi_dy(no1)=dphi_dy(no1)+area*dphidy;
    Ssupp(no1)=Ssupp(no1)+area;

    dphi_dx(no2)=dphi_dx(no2)+area*dphidx;
    dphi_dy(no2)=dphi_dy(no2)+area*dphidy;  
    Ssupp(no2)=Ssupp(no2)+area;

    dphi_dx(no3)=dphi_dx(no3)+area*dphidx;
    dphi_dy(no3)=dphi_dy(no3)+area*dphidy;
    Ssupp(no3)=Ssupp(no3)+area;

end

for i=1:Nnode
    dphi_dx(i)=dphi_dx(i)/Ssupp(i);
    dphi_dy(i)=dphi_dy(i)/Ssupp(i);
    Eabs(i)=sqrt(dphi_dx(i)^2+dphi_dy(i)^2);
end
% Add debugging info to check output
% fprintf('Computed gradients: dphi_dx range [%e, %e], dphi_dy range [%e, %e]\n', ...
%     min(dphi_dx), max(dphi_dx), min(dphi_dy), max(dphi_dy));

