#!/usr/bin/env python3
"""Write reference .graf files with the real graf/stardust Python
implementation, for MATLAB/Octave to read back and verify (see
check_python_grafs.m). Mirrors graf's own tests/conftest.py roundtrip
pattern.

Usage: gen_reference_grafs.py <graf_src_path> <out_dir>
"""
import sys

graf_src, out_dir = sys.argv[1], sys.argv[2]
sys.path.insert(0, graf_src)

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from graf.base import Graf

# --- Figure 1: two line traces on one axis -----------------------------
fig1, ax1 = plt.subplots()
x = np.linspace(0, 2 * np.pi, 100)
ax1.plot(x, np.sin(x), '-', color=(1, 0, 0), linewidth=2, label='sine')
ax1.plot(x, np.cos(x), '--', color=(0, 0, 1), marker='o', markersize=4, label='cosine')
ax1.set_xlabel('Angle (rad)')
ax1.set_ylabel('Value')
ax1.set_title('Trig functions')
ax1.grid(True)
g1 = Graf(fig=fig1, description='py_line_trace reference')
g1.write_graf(f"{out_dir}/py_line_trace.graf")
plt.close(fig1)

# --- Figure 2: 2x2 grid with a spanning axis + errorbar -----------------
fig2 = plt.figure()
axA = fig2.add_subplot(2, 2, 1)
axA.plot(range(1, 11), [i ** 2 for i in range(1, 11)])
axA.set_title('Quadratic')
axB = fig2.add_subplot(2, 2, 2)
axB.errorbar(range(1, 6), [2, 4, 3, 5, 4], yerr=[0.5, 0.3, 0.4, 0.2, 0.3])
axB.set_title('Errorbar')
axC = fig2.add_subplot(2, 2, (3, 4))
axC.plot(range(1, 11), range(1, 11))
axC.set_title('Wide')
g2 = Graf(fig=fig2, description='py_subplot_grid reference')
g2.write_graf(f"{out_dir}/py_subplot_grid.graf")
plt.close(fig2)

# --- Figure 3: surface plot with colorbar --------------------------------
fig3, ax3 = plt.subplots()
xv = np.arange(-2, 2.2, 0.2)
yv = np.arange(-2, 2.2, 0.2)
X, Y = np.meshgrid(xv, yv)
Z = X * np.exp(-X**2 - Y**2)
mesh = ax3.pcolormesh(X, Y, Z, shading='auto')
fig3.colorbar(mesh, ax=ax3, label='Amplitude')
ax3.set_title('Surf')
g3 = Graf(fig=fig3, description='py_surface reference')
g3.write_graf(f"{out_dir}/py_surface.graf")
plt.close(fig3)

print("wrote reference grafs to", out_dir)
