dphi_dx=zeros(Nel,1);  % Store x-direction gradient per element
dphi_dy=zeros(Nel,1);  % Store y-direction gradient per element
Eabs=zeros(Nnode,1);   % Electric field magnitude at nodes
Ssupp=zeros(Nnode,1);  % Support area for each node

% Store electric field components at nodes
Ex=zeros(Nnode,1);  % x-component of electric field
Ey=zeros(Nnode,1);  % y-component of electric field

for i=1:Nel
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
    
    % Store gradient values for each element
    dphi_dx(i) = dphidx;
    dphi_dy(i) = dphidy;
    
    % Calculate electric field components at nodes for visualization and field magnitude
    Ex(no1)=Ex(no1)+area*dphidx;
    Ey(no1)=Ey(no1)+area*dphidy;
    Ssupp(no1)=Ssupp(no1)+area;

    Ex(no2)=Ex(no2)+area*dphidx;
    Ey(no2)=Ey(no2)+area*dphidy;  
    Ssupp(no2)=Ssupp(no2)+area;

    Ex(no3)=Ex(no3)+area*dphidx;
    Ey(no3)=Ey(no3)+area*dphidy;
    Ssupp(no3)=Ssupp(no3)+area;

end

% Calculate electric field magnitude at nodes
for i=1:Nnode
    Ex(i)=Ex(i)/Ssupp(i);  % Normalize x-component of electric field
    Ey(i)=Ey(i)/Ssupp(i);  % Normalize y-component of electric field
    Eabs(i)=sqrt(Ex(i)^2+Ey(i)^2);  % Electric field magnitude
end

% Add debugging info to check output
% fprintf('Computed element gradients: dphi_dx range [%e, %e], dphi_dy range [%e, %e]\n', ...
%     min(dphi_dx), max(dphi_dx), min(dphi_dy), max(dphi_dy));
% fprintf('Computed nodal electric field: Ex range [%e, %e], Ey range [%e, %e]\n', ...
%     min(Ex), max(Ex), min(Ey), max(Ey));

return;