"""
Draw semiconductor geometry (no electrodes).

This script produces a simple 2D cross-section of the semiconductor stack
used in the provided sketch: a thick n+ substrate and a thin n-type GaAs layer
on top. All comments and printed output are in English. No text is placed
on the saved figure itself (per user request).

Output: saves `figures/semiconductor_geometry.png` in the repository.
"""

from pathlib import Path

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches


DEFAULT_OUTPUT = (
  Path(__file__).resolve().parents[1] / "figures" / "semiconductor_geometry.png"
)


def draw_semiconductor_geometry(save_path=DEFAULT_OUTPUT):
  """Draw the semiconductor layers and save the figure.

  Layers (units: micrometers):
  - n+ substrate: thickness = 2.0 µm
  - n-type GaAs: thickness = 0.1 µm
  - lateral width: 25.0 µm

  The saved image contains no on-figure text or annotations.
  """

  # Geometry in micrometers
  total_width = 25.0
  nplus_thickness = 2.0
  n_thickness = 0.1
  # n-type GaAs lateral width is 15 µm (centered on the substrate)
  n_width = 15.0

  # Create figure and axis
  fig_width = 8
  fig_height = 3
  fig, ax = plt.subplots(figsize=(fig_width, fig_height))

  # Draw n+ substrate (thick layer)
  substrate = patches.Rectangle((0, 0), total_width, nplus_thickness,
                  facecolor='none', edgecolor='black', linewidth=1.0)
  ax.add_patch(substrate)

  # Draw n-type GaAs (thin top layer) with specified lateral width
  # Left-aligned (aligned to substrate left edge) per user request
  n_layer_y = nplus_thickness
  n_x = 0.0
  n_layer = patches.Rectangle((n_x, n_layer_y), n_width, n_thickness,
                facecolor='none', edgecolor='black', linewidth=0.8)
  ax.add_patch(n_layer)

  # No on-figure text or dimension annotations per user request

  # Styling
  ax.set_aspect('equal')
  ax.set_xlim(-1, total_width + 5)
  ax.set_ylim(-1, nplus_thickness + n_thickness + 1)
  # Turn off default axes; we'll draw custom axes with origin at (0,0)
  ax.axis('off')

  # Draw custom X and Y axes with arrowheads (no text labels)
  axis_color = 'black'
  # X axis: from origin to the right
  ax.annotate('', xy=(total_width + 3, 0), xytext=(0, 0),
        arrowprops=dict(arrowstyle='->', color=axis_color, linewidth=1.0))
  # Y axis: from origin upward
  y_top = nplus_thickness + n_thickness + 0.8
  ax.annotate('', xy=(0, y_top), xytext=(0, 0),
        arrowprops=dict(arrowstyle='->', color=axis_color, linewidth=1.0))

  # Tick marks (no labels)
  x_ticks = [0, 5, 10, 15, 20, 25]
  tick_len = 0.15
  for xt in x_ticks:
    ax.plot([xt, xt], [0, -tick_len], color=axis_color, linewidth=1.0)
    # No numeric labels here; numeric labels are shown only at cutline positions

  y_ticks = [0.5, 1.0, 1.5, 2.0]
  for yt in y_ticks:
    ax.plot([-tick_len, 0], [yt, yt], color=axis_color, linewidth=1.0)
    # No numeric labels here; numeric labels are shown only at cutline positions

  # Axis direction labels (English)
  # Place X label near the arrow head of X axis
  ax.text(total_width + 3.4, -0.05, "X (µm)", ha='left', va='center', fontsize=10)
  # Place Y label near the arrow head of Y axis
  ax.text(-0.1, y_top + 0.3, "Y (µm)", ha='center', va='bottom', fontsize=10)

  # --- Cutlines requested by user ---
  # Draw ONLY one vertical cutline at x = 4.0 µm
  cut_x = [4.0]

  # Draw vertical cutline (red dashed)
  for cx in cut_x:
    ax.plot([cx, cx], [0, y_top], linestyle='--', color='red', linewidth=1.0, alpha=0.8)
    # X cutline numeric label (placed under the x-axis)
    ax.text(cx, -0.35, f"{cx:g}", ha='center', va='top', fontsize=9, color='red')

  # Save image and print confirmation to console (English output)
  save_path = Path(save_path)
  save_path.parent.mkdir(parents=True, exist_ok=True)
  plt.savefig(save_path, dpi=300, bbox_inches='tight')
  print(f"Saved geometry image to: {save_path}")
  plt.close(fig)


if __name__ == '__main__':
  draw_semiconductor_geometry()

