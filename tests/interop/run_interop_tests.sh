#!/usr/bin/env bash
# Cross-language round-trip test matrix for the tome format:
#   Python -> MATLAB, Python -> Octave, MATLAB -> Python, Octave -> Python.
#
# Usage:
#   STARDUST_PATH=/path/to/stardust MATLAB_BIN=/path/to/matlab \
#     ./run_interop_tests.sh
#
# Defaults assume stardust is checked out as a sibling of this repo, and
# that `matlab` and `octave` are on PATH.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
STARDUST_PATH="${STARDUST_PATH:-$(cd "$REPO_ROOT/../stardust" && pwd)}"
MATLAB_BIN="${MATLAB_BIN:-matlab}"
DATA_DIR="${DATA_DIR:-$HERE/data}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

mkdir -p "$DATA_DIR"

pass=0
fail=0

run_step() {
    local name="$1"
    shift
    echo "=== $name ==="
    if "$@"; then
        echo "--- PASS: $name ---"
        pass=$((pass + 1))
    else
        echo "--- FAIL: $name ---"
        fail=$((fail + 1))
    fi
    echo
}

octave_available() { command -v octave >/dev/null 2>&1; }
matlab_available() { command -v "$MATLAB_BIN" >/dev/null 2>&1 || [ -x "$MATLAB_BIN" ]; }

# 1. Python writes reference tomes.
run_step "python: generate reference tomes" \
    "$PYTHON_BIN" "$HERE/gen_reference_tomes.py" "$STARDUST_PATH" "$DATA_DIR"

# 2. MATLAB / Octave read them back and self-check.
if matlab_available; then
    run_step "matlab: read python-written tomes" \
        "$MATLAB_BIN" -batch "addpath('$REPO_ROOT/tome'); addpath('$HERE'); check_python_tomes('$DATA_DIR')"
else
    echo "skipping MATLAB checks: '$MATLAB_BIN' not found"
fi

if octave_available; then
    run_step "octave: read python-written tomes" \
        octave --no-gui --eval "addpath('$REPO_ROOT/tome'); addpath('$HERE'); check_python_tomes('$DATA_DIR')"
else
    echo "skipping Octave checks: 'octave' not found"
fi

# 3. MATLAB / Octave write reference tomes.
if matlab_available; then
    run_step "matlab: write reference tomes" \
        "$MATLAB_BIN" -batch "addpath('$REPO_ROOT/tome'); addpath('$HERE'); write_reference_tomes('$DATA_DIR')"
fi

if octave_available; then
    run_step "octave: write reference tomes" \
        octave --no-gui --eval "addpath('$REPO_ROOT/tome'); addpath('$HERE'); write_reference_tomes('$DATA_DIR')"
fi

# 4. Python reads them back and self-checks.
if matlab_available; then
    run_step "python: read matlab-written tomes" \
        "$PYTHON_BIN" "$HERE/check_matlab_tomes.py" "$STARDUST_PATH" "$DATA_DIR" matlab
fi

if octave_available; then
    run_step "python: read octave-written tomes" \
        "$PYTHON_BIN" "$HERE/check_matlab_tomes.py" "$STARDUST_PATH" "$DATA_DIR" octave
fi

echo "================================"
echo "interop tests: $pass passed, $fail failed"
echo "================================"
[ "$fail" -eq 0 ]
