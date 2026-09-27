% ===== Alternative Plotting Code (using plot lines for triangles) =====

% Unnormalize coordinates to physical units (cm) if Lo is available
if exist('Lo','var')
    x_phys = x_coords * Lo;
    y_phys = y_coords * Lo;
else
    x_phys = x_coords;
    y_phys = y_coords;
    warning('Lo not found in workspace. Using normalized coordinates for plotting.');
end

figure;
hold on;

% Plot elements using lines instead of fills
for i = 1:size(el_2d_no,1)
    nodes = el_2d_no(i,:);
    x_tri = x_phys(nodes);
    y_tri = y_phys(nodes);
    x_loop = [x_tri; x_tri(1)];
    y_loop = [y_tri; y_tri(1)];
    
    if el_mat_2d(i) == 1
        plot(x_loop, y_loop, 'b-', 'LineWidth', 0.5);  % Blue line for n+
    else
        plot(x_loop, y_loop, 'r-', 'LineWidth', 0.5);  % Red line for n
    end
end

xlabel('x [cm]');
ylabel('y [cm]');
ylim([0 max(y_phys)]);
% axis equal;
grid on;
box on;
