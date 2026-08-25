#!/usr/bin/env python3
"""Read tome files written by MATLAB/Octave (write_reference_tomes.m)
and verify them with the Python reference implementation.

Usage: check_matlab_tomes.py <stardust_repo_path> <data_dir> <tag>
where <tag> is 'matlab' or 'octave', matching the filename prefix used
by write_reference_tomes.m.
"""
import sys
import numpy as np

stardust_path, data_dir, tag = sys.argv[1], sys.argv[2], sys.argv[3]
sys.path.insert(0, stardust_path)
from stardust.tome import tome_to_dict


def check(cond, msg):
    if not cond:
        raise AssertionError(msg)


def check_worked_example():
    d = tome_to_dict(f"{data_dir}/{tag}_worked_example.tome")
    check(d["run_id"] == 4, "run_id")
    check(d["passed"] is True, "passed")
    check(d["note"] == "ok", "note")
    check(np.allclose(d["sweep"], [0.0, 0.5, 1.0]), "sweep")
    check(d["labels"] == ["cold", "hot"], "labels")
    check(d["settings"]["gain"] == 2.5, "settings.gain")
    check(len(d["events"]) == 2, "events len")
    check(d["events"][0]["t"] == 0.1, "events[0].t")
    check(d["events"][1]["t"] == 9.4, "events[1].t")
    print(f"  ok: {tag}_worked_example.tome")


def check_kitchen_sink():
    d = tome_to_dict(f"{data_dir}/{tag}_kitchen_sink.tome")
    check(d["run_id"] == 4, "run_id")
    check(d["passed"] is True, "passed")
    check(d["note"] == "hello world", "note")
    check(d["empty_str"] == "", "empty_str")
    check(abs(d["pi_val"] - 3.14159) < 1e-9, "pi_val")
    check(abs(d["z"] - (3.5 - 2.25j)) < 1e-9, "z")
    check(np.allclose(np.ravel(d["sweep"]), np.linspace(0, 1, 11)), "sweep")
    check(d["mat"].shape == (3, 4), f"mat shape {d['mat'].shape}")
    check(np.array_equal(d["mat"], np.arange(12).reshape(3, 4)), "mat values")
    check(d["big"].shape == (3, 4, 5), f"big shape {d['big'].shape}")
    expected_big = np.arange(1, 61).reshape((3, 4, 5), order="F")
    check(np.array_equal(d["big"], expected_big), "big values")
    check(d["logical_mat"].dtype == np.bool_, "logical_mat dtype")
    check(np.array_equal(d["logical_mat"],
                          np.array([[True, False, True], [False, False, True]])),
          "logical_mat values")
    check(np.allclose(np.ravel(d["zvec"]), [1 + 2j, 3 - 4j, 5 + 6j]), "zvec")
    check(d["labels"] == ["cold", "warm", "hot"], "labels")
    check(list(d["empty_list"]) == [], "empty_list")
    check(d["settings"]["gain"] == 2.5 and d["settings"]["mode"] == "auto", "settings")
    check(d["deep"]["deeper"]["deepest"] == "found it", "deep nesting")
    check(len(d["events"]) == 2, "events len")
    check(d["events"][0]["kind"] == "start", "events[0].kind")
    check(d["events"][1]["kind"] == "stop", "events[1].kind")
    print(f"  ok: {tag}_kitchen_sink.tome")


def check_records():
    d = tome_to_dict(f"{data_dir}/{tag}_records.tome")
    check(isinstance(d, list), "root should be a list")
    check(len(d) == 100, "records len")
    check(d[0]["i"] == 0 and d[0]["sq"] == 0, "records[0]")
    check(d[10]["i"] == 10 and d[10]["sq"] == 100, "records[10]")
    check(d[99]["i"] == 99 and d[99]["sq"] == 99 * 99, "records[99]")
    print(f"  ok: {tag}_records.tome")


check_worked_example()
check_kitchen_sink()
check_records()
print(f"check_matlab_tomes.py ({tag}): all checks passed")
