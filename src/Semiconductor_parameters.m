% Calculation Parameters
T=300;          % Absolute Temperaature (K)
mn=0.067*me;     % Effective mass of electrons (GaAs)
mnn=0.09*me;     % Effective mass of electrons (GaAlAs)
Ec=1.42;        % Conduction energy level (eV)
Ev=0.;          % Valence energy level (eV)
eps_r=12.9;     % Relative permittivity of GaAs-block (intrinsic)
eps_0=8.85e-12; % Permittivity of Vacuum (F/m)
mu_n_i=8.50e3;  % Mobility of Electrons at 300K (cm^2/(Vs))
mu_p_i=0.40e3;  % Mobility of Holes at 300K (cm^2/(Vs))
n_i=2.1e6;    % Intrinsic carrier density (cm^-3) ???
tau_n=10e-6;    % Time constant of electrons (s)
tau_p=10e-6;    % Time constant of holes (s)

% check constants
Nd=2e17;        % GaAs n (cm^-3) 
Ed=Ec-0.006;    
Nd_n = 2e18;    % GaAlAs n+ (cm^-3) 
Ed_n = Ec-0.006;

VT = kB*T/e;    % Thermal voltage (V)
bi=VT*log(Nd/n_i);
bi_n=VT*log(Nd_n/n_i);

Na=0;           
Ea=Ev;          

% Mobilities in the doped semiconductor 
mu_n=8.5e3;    % (cm^2/(Vs)) 8500
mu_p=0.40e3;    % (cm^2/(Vs)) 400

Et=kB*T;
E_eV=e*1;
Et_eV=Et/E_eV;

% Built in Voltage of the PN-junction
% Vbi=kB*T/e*log(Na*Nd/n_i^2);
