%% 23.04.2021 - Arif Gungor 

tt=figure('pos',[50 50 1450 750]);

subplot(1,4,1);
plot(x_no*1e4, phi*Vt,'linewidth',2);

set(gca,'fontsize', 12);
set(gca,'linewidth',2);
grid on;
xlabel('x [\mum]');
ylabel('Potential [V]');

subplot(1,4,2);
plot(x_no*1e4, p_2*n_i,'linewidth',2);
hold on;
plot(x_no*1e4, n_2*n_i,'linewidth',2);
hold off;
legend('p', 'n','location','east');
set(gca,'fontsize', 12);
set(gca,'linewidth',2);
grid on;
xlabel('x [\mum]');
ylabel('Charge Concentration [cm^{-3}]');

subplot(1,4,3);
semilogy(x_no*1e4, p_2*n_i,'linewidth',2);
hold on;
semilogy(x_no*1e4, n_2*n_i,'linewidth',2);
hold off;
legend('p', 'n','location','east');
set(gca,'fontsize', 12);
set(gca,'linewidth',2);
grid on;
xlabel('x [\mum]');
ylabel('Charge Concentration [cm^{-3}]');


subplot(1,4,4);
plot(x_no*1e4, 1.6*1e-19.*rho_t(:,end)*n_i,'linewidth',2);
set(gca,'fontsize', 12);
set(gca,'linewidth',2);
grid on;
xlabel('x [\mum]');
ylabel('Charge Concentration [C/cm^{-3}]');

