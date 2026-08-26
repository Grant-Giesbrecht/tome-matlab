#!/usr/bin/env bash
# Cross-language round-trip test matrix for GrAF (built on tome):
#   Python graf -> MATLAB, Python graf -> Octave,
#   MATLAB graf -> Python graf, Octave graf -> Python graf.
#
# Usage:
#   GRAF_PATH=/path/to/graf STARDUST_PATH=/path/to/stardust \
#     MATLAB_BIN=/path/to/matlab ./run_graf_interop_tests.sh
#
# Defaults assume graf/stardust are checked out as siblings of this
# repo, and that `matlab`/`octave` are on PATH.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
GRAF_PATH="${GRAF_PATH:-$(cd "$REPO_ROOT/../graf/src" && pwd)}"
STARDUST_PATH="${STARDUST_PATH:-$(cd "$REPO_ROOT/../stardust" && pwd)}"
MATLAB_BIN="${MATLAB_BIN:-matlab}"
DATA_DIR="${DATA_DIR:-$HERE/graf_data}"
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

# 1. Python (real graf package) writes reference .graf files.
run_step "python: generate reference grafs" \
    "$PYTHON_BIN" "$HERE/gen_reference_grafs.py" "$GRAF_PATH" "$DATA_DIR"

# 2. MATLAB / Octave read them back via readgraf and self-check.
if matlab_available; then
    run_step "matlab: read python-written grafs" \
        "$MATLAB_BIN" -batch "addpath('$REPO_ROOT/tome'); addpath('$REPO_ROOT/graf'); addpath('$HERE'); check_python_grafs('$DATA_DIR')"
else
    echo "skipping MATLAB checks: '$MATLAB_BIN' not found"
fi

if octave_available; then
    run_step "octave: read python-written grafs" \
        octave --no-gui --eval "addpath('$REPO_ROOT/tome'); addpath('$REPO_ROOT/graf'); addpath('$HERE'); check_python_grafs('$DATA_DIR')"
else
    echo "skipping Octave checks: 'octave' not found"
fi

# 3. MATLAB / Octave write reference .graf files via writegraf.
if matlab_available; then
    run_step "matlab: write reference grafs" \
        "$MATLAB_BIN" -batch "addpath('$REPO_ROOT/tome'); addpath('$REPO_ROOT/graf'); addpath('$HERE'); write_reference_grafs('$DATA_DIR')"
fi

if octave_available; then
    run_step "octave: write reference grafs" \
        octave --no-gui --eval "addpath('$REPO_ROOT/tome'); addpath('$REPO_ROOT/graf'); addpath('$HERE'); write_reference_grafs('$DATA_DIR')"
fi

# 4. Python (real graf package) reads them back and self-checks.
if matlab_available; then
    run_step "python: read matlab-written grafs" \
        "$PYTHON_BIN" "$HERE/check_matlab_grafs.py" "$GRAF_PATH" "$STARDUST_PATH" "$DATA_DIR" matlab
fi

if octave_available; then
    run_step "python: read octave-written grafs" \
        "$PYTHON_BIN" "$HERE/check_matlab_grafs.py" "$GRAF_PATH" "$STARDUST_PATH" "$DATA_DIR" octave
fi

echo "================================"
echo "graf interop tests: $pass passed, $fail failed"
echo "================================"
[ "$fail" -eq 0 ]
