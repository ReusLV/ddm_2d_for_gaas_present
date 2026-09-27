% Normalization Parameters for Semiconductor Equations
% February 25, 2019


Vt=kB*T/e;                              % Thermal Voltage (V)
Lo=sqrt(0.01*eps_0*eps_r*Vt/(e*n_i));   % Length normalization parameter (cm)
Dn=Vt*mu_n;                             % Diffusion constant of electrons (cm^2/s)
Dp=Vt*mu_p;                             % Diffusion constant of holes (cm^2/s)
Do=Dp;                                  % Diffusion normalization parameter (cm^2/s)
to=Lo^2/Do;                             % Time normalizatio parameter (s)
Mo=Do/Vt;                               % Mobility normalization parameter (cm^2/(Vs))
Go=n_i/to;                              % Net Gen./Rec. Rate norm. par. (cm^-3/s)
Jo=Do*e*n_i/Lo;                         % Current density norm. par. (A/cm^2)

