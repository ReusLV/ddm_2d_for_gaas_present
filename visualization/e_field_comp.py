"""Electric field comparison plotting script.

Reads two files in the same directory:
	Eabs_top_electrode_fine.txt   -> legend: fine
	Eabs_top_electrode_efine.txt  -> legend: extra fine (file name uses 'efine')

Automatic data format handling:
1) Multi-column (>=2): first column used as x, last column used as y
2) Single column: row index (starting at 0) used as x, the column values as y
3) Lines starting with # or % are ignored as comments

Usage examples:
	python e_field_comp.py                      # show only
	python e_field_comp.py --save fig.png       # save only (no window unless --show)
	python e_field_comp.py --show --save out.png

Optional arguments:
	--fine <path>     path to fine data file (default: Eabs_top_electrode_fine.txt)
	--efine <path>    path to extra fine data file (default: Eabs_top_electrode_efine.txt)
	--xlabel <label>  x-axis label (default: Position)
	--ylabel <label>  y-axis label (default: |E| (a.u.))
	--title  <title>  figure title
	--xscale/--yscale linear or log
	--dpi <int>       save resolution (default 180)

Dependencies: numpy, matplotlib (install with: pip install numpy matplotlib)
"""

from __future__ import annotations
import argparse
from pathlib import Path
import sys
from typing import Tuple

import numpy as np
import matplotlib


DEFAULT_DATA_DIR = (
	Path(__file__).resolve().parents[1]
	/ "comsol_reference"
	/ "cutline"
	/ "top_electrode"
)


def load_numeric_table(path: Path) -> Tuple[np.ndarray, np.ndarray]:
	"""Load a numeric table file and return (x, y) arrays.

	Strategy:
	  - Skip blank lines and lines beginning with # or %
	  - Use numpy.genfromtxt (auto delimiter detection for whitespace/commas)
	  - If resulting array is 1-D: use index as x
	  - If 2-D or more: x = first column, y = last column
	"""
	if not path.exists():
		raise FileNotFoundError(f"File not found: {path}")

	# Pre-read and filter to a buffer so genfromtxt handles irregular whitespace
	cleaned_lines = []
	with path.open('r', encoding='utf-8', errors='ignore') as f:
		for line in f:
			s = line.strip()
			if not s:
				continue
			if s.startswith('#') or s.startswith('%'):
				continue
			cleaned_lines.append(s)

	if not cleaned_lines:
		raise ValueError(f"No usable data in file: {path}")

	from io import StringIO
	buf = StringIO("\n".join(cleaned_lines))

	try:
		data = np.genfromtxt(buf, delimiter=None)  # auto delimiter detection
	except Exception as e:
		raise ValueError(f"Failed to parse file {path}: {e}") from e

	if data.ndim == 0:
		raise ValueError(f"File contains only a scalar; cannot plot: {path}")
	if data.ndim == 1:
		y = data
		x = np.arange(len(y))
	else:
		# Multi-column: first col as x, last col as y
		x = data[:, 0]
		y = data[:, -1]

	return x, y


def build_parser() -> argparse.ArgumentParser:
	p = argparse.ArgumentParser(description="Compare fine vs extra fine field data")
	p.add_argument('--fine', default=DEFAULT_DATA_DIR / 'Eabs_top_electrode_fine.txt', help='path to fine data file')
	p.add_argument('--efine', default=DEFAULT_DATA_DIR / 'Eabs_top_electrode_efine.txt', help='path to extra fine (efine) data file')
	p.add_argument('--xlabel', default='electrode position [μm]', help='x-axis label')
	p.add_argument('--ylabel', default='|E| [V/cm]', help='y-axis label')
	p.add_argument('--title', default='', help='figure title')
	p.add_argument('--xscale', default='linear', choices=['linear', 'log'])
	p.add_argument('--yscale', default='linear', choices=['linear', 'log'])
	p.add_argument('--save', metavar='PATH', help='output image file name (e.g. figure.png)')
	p.add_argument('--dpi', type=int, default=180, help='save resolution in DPI')
	p.add_argument('--show', action='store_true', help='show the figure (if omitted and --save used, no window)')
	p.add_argument('--debug', action='store_true', help='print resolved file paths and extra debug info')
	p.add_argument('--logy', action='store_true', help='shortcut: set y-axis to log scale (overrides --yscale)')
	return p


def main(argv=None):
	args = build_parser().parse_args(argv)
	if args.save and not args.show:
		matplotlib.use('Agg')
	import matplotlib.pyplot as plt

	fine_path = Path(args.fine)
	efine_path = Path(args.efine)

	if args.debug:
		print("[DEBUG] Fine file (raw arg):", args.fine)
		print("[DEBUG] Extra fine file (raw arg):", args.efine)
		print("[DEBUG] Fine file resolved path:", fine_path.resolve())
		print("[DEBUG] Extra fine file resolved path:", efine_path.resolve())
		print("[DEBUG] Attempting to load data...")

	x1, y1 = load_numeric_table(fine_path)
	x2, y2 = load_numeric_table(efine_path)

	if args.debug:
		print(f"[DEBUG] Loaded fine shape: x={x1.shape}, y={y1.shape}")
		print(f"[DEBUG] Loaded extra fine shape: x={x2.shape}, y={y2.shape}")

	# Apply log y shortcut if requested
	if 'args' in locals() and getattr(args, 'logy', False):
		args.yscale = 'log'

	# If x domains differ, we still plot both directly; user can interpret differences.
	fig, ax = plt.subplots(figsize=(6.0, 4.0), dpi=110)
	ax.plot(x1, y1, label='fine', lw=1.6, color='#1f77b4')
	ax.plot(x2, y2, label='extra fine', lw=1.4, color='#d62728', alpha=0.85)

	ax.set_xlabel(args.xlabel)
	ax.set_ylabel(args.ylabel)
	ax.set_title(args.title)
	ax.set_xscale(args.xscale)
	ax.set_yscale(args.yscale)
	ax.grid(True, ls='--', alpha=0.35)
	ax.legend(frameon=True)
	fig.tight_layout()

	if args.save:
		out_path = Path(args.save)
		fig.savefig(out_path, dpi=args.dpi)
		print(f"Saved figure: {out_path.resolve()}")

	# Show if explicitly requested or nothing was saved.
	if args.show or not args.save:
		plt.show()
	else:
		plt.close(fig)


if __name__ == '__main__':
	try:
		main()
	except Exception as e:
		print(f"Error: {e}", file=sys.stderr)
		sys.exit(1)

