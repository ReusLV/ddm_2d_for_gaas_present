% constants
q = 1.602176634e-19; % Elementary charge in Coulombs
An = 110; % A/cm^2/K^2, Richardson constant for GaAs
Ap = 90; % A/cm^2/K^2, Richardson constant for GaAs
T = 300; % Temperature in Kelvin
k_B = 8.617333262145e-5; % Boltzmann constant in eV/K
chi0 = 4.07; % Electron affinity for GaAs in eV
phim = 4.5; % Metal work function in eV (example value)
phiB = phim-chi0; % Schottky barrier height in eV (example value)

Veq_adj = 0.04; % Additional adjustment to the equilibrium potential if needed
% Nc = 4.7e17; % Effective density of states in the conduction band for GaAs (cm^-3)
% Nv = 7e18; % Effective density of states in the valence band
Nv = (T^(3/2)) * 1.83e15
Nc = 8.63e13 * T^(3/2) * ( ...
       1 - 1.93e-4*T ...
         - 4.19e-8*T^2 ...
         + 21*exp(-0.29*q/kB/T) ...
         + 44*exp(-0.48*q/kB/T) )

Eg = 1.42; % Bandgap energy for GaAs in eV
n_sc = Nc * exp(-(phiB) / (k_B * T)); % Electron concentration at the Schottky contact
p_sc = Nv * exp(-(Eg - phiB) / (k_B * T));
vsn = An*T^2 / q / Nc;
vsp = Ap*T^2 / q / Nv;

% Normalized constants for use in the solver
n_sc = n_sc / n_i;
p_sc = p_sc / n_i;
vsn = vsn / (Do / Lo);
vsp = vsp / (Do / Lo);
qn = 1; % Normalized electron charge
qp = -1; % Normalized hole charge
