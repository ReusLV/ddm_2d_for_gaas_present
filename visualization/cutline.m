function cutline(save_path)
% Draw semiconductor geometry (no electrodes) and save as PNG.
% MATLAB translation of cutline.py
%
% Usage:
%   cutline();                      % saves to 'semiconductor_geometry.png'
%   cutline('my_geom.png');         % custom output path/name
%
% Layers (units: micrometers):
% - n+ substrate: thickness = 2.0 µm
% - n-type GaAs: thickness = 0.1 µm (left-aligned, width = 15 µm)
% - lateral total width: 25.0 µm

  if nargin < 1
    save_path = 'semiconductor_geometry.png';
  end

  % Geometry in micrometers
  total_width = 25.0;
  nplus_thickness = 2.0;
  n_thickness = 0.1;
  n_width = 15.0;   % lateral width of the n-type GaAs (left-aligned)

  % Figure setup
  fig = figure('Units','pixels','Position',[100 100 800 300],'Color','w'); %#ok<NASGU>
  ax = axes();
  hold(ax,'on');

  % Draw n+ substrate (thick layer)
  rectangle('Position',[0, 0, total_width, nplus_thickness], ...
            'EdgeColor','k','LineWidth',1.0,'FaceColor','none','Parent',ax);

  % Draw n-type GaAs (thin top layer), left-aligned at x=0
  n_layer_y = nplus_thickness;
  n_x = 0.0;
  rectangle('Position',[n_x, n_layer_y, n_width, n_thickness], ...
            'EdgeColor','k','LineWidth',0.8,'FaceColor','none','Parent',ax);

  % Styling and limits
  axis(ax,'equal');
  xlim(ax,[-1, total_width + 5]);
  ylim(ax,[-1, nplus_thickness + n_thickness + 1]);
  axis(ax,'off');

  % Draw custom X and Y axes with arrowheads using quiver
  axis_color = [0 0 0];
  y_top = nplus_thickness + n_thickness + 0.8;
  % X axis: from origin to the right
  quiver(ax, 0, 0, total_width + 3, 0, 0, 'Color', axis_color, ...
         'LineWidth', 1.0, 'MaxHeadSize', 0.5, 'AutoScale', 'off');
  % Y axis: from origin upward
  quiver(ax, 0, 0, 0, y_top, 0, 'Color', axis_color, ...
         'LineWidth', 1.0, 'MaxHeadSize', 0.5, 'AutoScale', 'off');

  % Tick marks (no numeric labels except at cutlines)
  x_ticks = [0 5 10 15 20 25];
  tick_len = 0.15;
  for xt = x_ticks
    plot(ax, [xt xt], [0 -tick_len], 'Color', axis_color, 'LineWidth', 1.0);
  end
  y_ticks = [0.5 1.0 1.5 2.0];
  for yt = y_ticks
    plot(ax, [-tick_len 0], [yt yt], 'Color', axis_color, 'LineWidth', 1.0);
  end

  % Axis direction labels (English), near arrow heads (use TeX for micro)
  text(total_width + 3.4, -0.05, 'X (\mum)', 'Parent', ax, ...
       'HorizontalAlignment','left', 'VerticalAlignment','middle', 'FontSize',10, 'Interpreter','tex');
  text(-0.1, y_top + 0.3, 'Y (\mum)', 'Parent', ax, ...
       'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize',10, 'Interpreter','tex');

  % Cutlines
  cut_x = [2.0, 4.0, 15.2];   % vertical cutlines at x (µm)
  cut_y = [1.0, 2.05];        % horizontal cutlines at y (µm)

  % Vertical cutlines (red dashed) + numeric labels below x-axis
  for cx = cut_x
    plot(ax, [cx cx], [0 y_top], '--', 'Color', [1 0 0], 'LineWidth', 1.0);
    text(cx, -0.35, sprintf('%g', cx), 'Parent', ax, 'Color', [1 0 0], ...
         'HorizontalAlignment','center', 'VerticalAlignment','top', 'FontSize',9);
  end

  % Horizontal cutlines (red dashed) + numeric labels left of y-axis
  for cy = cut_y
    plot(ax, [0 total_width], [cy cy], '--', 'Color', [1 0 0], 'LineWidth', 1.0);
    text(-0.35, cy, sprintf('%g', cy), 'Parent', ax, 'Color', [1 0 0], ...
         'HorizontalAlignment','right', 'VerticalAlignment','middle', 'FontSize',9);
  end

  % Save image (300 DPI)
  try
    exportgraphics(ax, save_path, 'Resolution', 300, 'BackgroundColor', 'white');
  catch
    set(gcf, 'PaperPositionMode', 'auto');
    print(gcf, save_path, '-dpng', '-r300');
  end
  disp(['Saved geometry image to: ' save_path]);
  close(gcf);
end
