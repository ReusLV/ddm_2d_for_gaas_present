% plot(x_no,zeros(size(x_no,1)),'*-', 'linewidth',1); 
% xlabel('x [cm]');
% ylim([-0.1, 0.1]);
% ylim([0, 0.1]);
% set(gca,'ytick',[])
% set(gca,'yticklabel',[])

% my version
figure;

x_coords = x_coords*Lo; % convert to cm
y_coords = y_coords*Lo; % convert to cm
L_nn = L_nn*Lo; % convert to cm
L_n = L_n*Lo; % convert to cm
H1 = H1*Lo; % convert to cm
H2 = H2*Lo; % convert to cm
e_start = e_start*Lo; % convert to cm
e_end = e_end*Lo; % convert to cm

% Assign different colors to nodes in different regions
node_colors = zeros(length(x_coords), 3);
for i = 1:length(x_coords)
    if y_coords(i) <= H1  % Lower n+ region
        node_colors(i,:) = [0, 0, 1];  % Blue
    else  % Upper n region
        node_colors(i,:) = [1, 0, 0];  % Red
    end
end

% Plot nodes
% scatter(x_coords, y_coords, 10, node_colors, 'filled');
hold on;

% Plot boundaries
plot([0 L_nn], [0 0], 'k-', 'LineWidth', 1);        % Bottom boundary
plot([0 L_nn], [H1 H1], 'k-', 'LineWidth', 1);      % Middle boundary
plot([0 L_n], [H1+H2 H1+H2], 'k-', 'LineWidth', 1); % Top boundary
plot([0 0], [0 H1+H2], 'k-', 'LineWidth', 1);       % Left boundary
plot([L_nn L_nn], [0 H1], 'k-', 'LineWidth', 1); % Right boundary (diagonal)
plot([L_n L_n], [H1 H1+H2], 'k-', 'LineWidth', 1); % Right boundary (diagonal)
plot([e_start e_end], [H1+H2 H1+H2], 'm-', 'LineWidth', 2); % Top electrode
plot([L_n L_n], [H1 H1+H2], 'b-', 'LineWidth', 2); % n right electrode
plot([L_n L_nn], [H1 H1], 'b-', 'LineWidth', 2); % n+ top electrode

xlabel('x [cm]');
ylabel('y [cm]');
ylim([-0.1*H1, (H1+H2+0.1*H1)]);
box on;
grid on;

x_coords = x_coords/Lo; % convert back to normalized
y_coords = y_coords/Lo; % convert back to normalized
L_nn = L_nn/Lo; % convert back to normalized
L_n = L_n/Lo; % convert back to normalized
H1 = H1/Lo; % convert back to normalized
H2 = H2/Lo; % convert back to normalized
e_start = e_start/Lo; % convert back to normalized
e_end = e_end/Lo; % convert back to normalized
