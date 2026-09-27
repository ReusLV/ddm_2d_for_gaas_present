% Define Initial Conditions

% Equilibrium values
n_n=0.5*(Nd+sqrt(Nd^2+4*n_i^2))/n_i;
p_n=1/n_n;

n_nn=0.5*(Nd_n+sqrt(Nd_n^2+4*n_i^2))/n_i;
p_nn=1/n_nn;
    
N_a=zeros(Nnode,1); % Acceptor concentration
N_d=zeros(Nnode,1); % Donor concentration
p0=zeros(Nnode,1);  % Initial hole concentration
n0=zeros(Nnode,1);  % Initial electron concentration

for i = 1:Nnode           
    if y_coords(i) <= H1                                              
        N_d(i) = Nd_n / n_i;
        n0(i) = n_nn;
        p0(i) = p_nn;
    else                                                            
        N_d(i) = Nd / n_i;
        n0(i) = n_n;
        p0(i) = p_n;
    end
end

