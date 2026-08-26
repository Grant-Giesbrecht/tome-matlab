#!/usr/bin/env python3
"""Read .graf files written by MATLAB/Octave (write_reference_grafs.m)
and verify them from the Python side.

MATLAB-authored files are checked via the real Python graf package's own
Graf class (graf.base.Graf.read_graf), exercising its full
Packable.unpack() chain against a MATLAB-authored file.

Octave-authored files are checked via stardust.tome.tome_to_dict
directly instead: Octave cannot write an empty HDF5 group (no low-level
API in hdf5oct), so writegraf omits an axis's empty 'traces' or
'surfaces' dict rather than erroring (see
graf/private/grafStripEmptyDictsForOctave.m). That is faithfully
readable tome data — which is what's actually being tested here — but
graf's own Packable.unpack() does not tolerate a missing dict_manifest
key and raises for that axis. This is verified explicitly below as a
known, documented, Octave-only limitation, not silently worked around.

Usage: check_matlab_grafs.py <graf_src_path> <stardust_src_path> <data_dir> <tag>
where <tag> is 'matlab' or 'octave'.
"""
import sys

graf_src, stardust_src, data_dir, tag = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
sys.path.insert(0, graf_src)
sys.path.insert(0, stardust_src)

import matplotlib
matplotlib.use('Agg')
import numpy as np


def check(cond, msg):
    if not cond:
        raise AssertionError(msg)


def check_kitchen_sink_matlab():
    from graf.base import Graf
    g = Graf()
    g.read_graf(f"{data_dir}/{tag}_kitchen_sink.graf")
    check(g.info.description == f"{tag} kitchen sink reference", "description")
    check(g.supertitle == "Kitchen Sink", "supertitle")
    ax0 = g.axes["Ax0"]
    check(ax0.title == "Axis 1", "axis title")
    check(ax0.grid_on is True, "grid_on")
    check(ax0.x_axis.label == "Time (s)", "x label")
    tr0 = ax0.traces["Tr0"]
    check(tr0.display_name == "sine", "trace display_name")
    check(np.allclose(tr0.y_data, np.sin(np.linspace(0, 10, 50))), "trace y_data")
    check(tr0.has_error_bars is True, "has_error_bars")
    ax1 = g.axes["Ax1"]
    check(ax1.axis_type == "AXIS_SURFACE", "axis_type")
    sf0 = ax1.surfaces["Sf0"]
    check(np.array(sf0.z_grid).shape == (9, 9), f"z_grid shape {np.array(sf0.z_grid).shape}")
    print(f"  ok: {tag}_kitchen_sink.graf (via Graf.read_graf)")


def check_kitchen_sink_octave():
    from stardust.tome import tome_to_dict
    d = tome_to_dict(f"{data_dir}/{tag}_kitchen_sink.graf")
    check(d["info"]["description"] == f"{tag} kitchen sink reference", "description")
    check(d["supertitle"] == "Kitchen Sink", "supertitle")
    ax0 = d["axes"]["Ax0"]
    check(ax0["title"] == "Axis 1", "axis title")
    check(ax0["grid_on"] is True, "grid_on")
    check(ax0["x_axis"]["label"] == "Time (s)", "x label")
    tr0 = ax0["traces"]["Tr0"]
    check(tr0["display_name"] == "sine", "trace display_name")
    check(np.allclose(tr0["y_data"], np.sin(np.linspace(0, 10, 50))), "trace y_data")
    check(tr0["has_error_bars"] is True, "has_error_bars")
    # Confirmed correctly OMITTED (not a dropped-data bug): Octave cannot
    # write the empty 'surfaces' dict this axis would otherwise have.
    check("surfaces" not in ax0, "Ax0.surfaces should have been omitted by Octave")
    ax1 = d["axes"]["Ax1"]
    check(ax1["axis_type"] == "AXIS_SURFACE", "axis_type")
    sf0 = ax1["surfaces"]["Sf0"]
    check(np.array(sf0["z_grid"]).shape == (9, 9), f"z_grid shape {np.array(sf0['z_grid']).shape}")
    print(f"  ok: {tag}_kitchen_sink.graf (via tome_to_dict, since Ax0.surfaces is missing)")

    # Now confirm the *documented* limitation actually reproduces: a raw
    # Graf.read_graf() call must fail on this same file, specifically
    # because of the missing dict_manifest key. If graf's Packable.unpack()
    # is ever hardened to tolerate this, this assertion (not the round
    # trip itself) is what should start failing.
    from graf.base import Graf
    g = Graf()
    g.read_graf(f"{data_dir}/{tag}_kitchen_sink.graf")
    check("Ax0" not in g.axes, "expected graf's raw Graf.read_graf() to still choke on the "
                                "Octave-omitted empty dict; if this now succeeds, graf.base.Packable.unpack "
                                "was hardened and check_matlab_grafs.py should be simplified")
    print(f"  ok: confirmed the documented Graf.read_graf() limitation still reproduces on this file")


def check_line_trace():
    from graf.base import Graf
    g = Graf()
    g.read_graf(f"{data_dir}/{tag}_line_trace.graf")
    check(g.info.description == f"{tag} line trace reference", "description")
    ax0 = g.axes["Ax0"]
    check(ax0.title == "Trig functions", "title")
    check(len(ax0.traces) == 2, f"n traces {len(ax0.traces)}")
    tr0 = ax0.traces["Tr0"]
    check(tr0.display_name == "sine", "tr0 display_name")
    check(np.allclose(tr0.line_color, [1, 0, 0]), "tr0 line_color")
    tr1 = ax0.traces["Tr1"]
    check(tr1.display_name == "cosine", "tr1 display_name")
    check(tr1.marker_type == "o", "tr1 marker_type")
    print(f"  ok: {tag}_line_trace.graf")


if tag == "octave":
    check_kitchen_sink_octave()
else:
    check_kitchen_sink_matlab()
    check_line_trace()
print(f"check_matlab_grafs.py ({tag}): all checks passed")
