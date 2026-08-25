#!/usr/bin/env python3
"""Write a set of reference tome files with the Python implementation.

Used by the MATLAB/Octave -> Python leg of the interop test: MATLAB and
Octave each read these files and check the values against known-good
constants (see check_read_in_matlab.m).
"""
import sys
import numpy as np

sys.path.insert(0, sys.argv[1])
from stardust.tome import dict_to_tome

out_dir = sys.argv[2]

worked_example = {
    "run_id": 4,
    "passed": True,
    "note": "ok",
    "sweep": np.array([0.0, 0.5, 1.0]),
    "labels": ["cold", "hot"],
    "mixed": [1, "a", None],
    "nothing": None,
    "settings": {"gain": 2.5},
    "events": [{"t": 0.1}, {"t": 9.4}],
}
assert dict_to_tome(worked_example, f"{out_dir}/py_worked_example.tome")

kitchen_sink = {
    "run_id": 4,
    "passed": True,
    "note": "hello world",
    "empty_str": "",
    "pi_val": 3.14159,
    "z": 3.5 - 2.25j,
    "sweep": np.linspace(0.0, 1.0, 11),
    "mat": np.arange(12, dtype="float64").reshape(3, 4),
    "big": np.arange(1, 61, dtype="float64").reshape(3, 4, 5),
    "logical_mat": np.array([[True, False, True], [False, False, True]]),
    "zvec": np.array([1 + 2j, 3 - 4j, 5 + 6j]),
    "labels": ["cold", "warm", "hot"],
    "empty_list": [],
    "settings": {"gain": 2.5, "mode": "auto"},
    "deep": {"deeper": {"deepest": "found it"}},
    "events": [
        {"t": 0.1, "kind": "start"},
        {"t": 9.4, "kind": "stop"},
    ],
}
assert dict_to_tome(kitchen_sink, f"{out_dir}/py_kitchen_sink.tome")

records = [{"i": i, "sq": i * i} for i in range(100)]
assert dict_to_tome(records, f"{out_dir}/py_records.tome")

print("wrote reference tomes to", out_dir)
