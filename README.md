# tome-matlab

A MATLAB/Octave reader and writer for the **tome** file format: an HDF5
file that stores a nested `dict`/`struct` (or a list of them) in a
self-describing way, so a reader gets back the same shapes and types
that were written. The format is defined by
[stardust's Python implementation](../stardust/stardust/tome.py) and
[format specification](../stardust/docs/tome/format.md); this repo is an
independent implementation of the same on-disk format for MATLAB and
GNU Octave, verified to round-trip against the Python reference reader
and writer.

Tested against MATLAB R2026a, MATLAB R2019b, and GNU Octave 11.3 (with
the [hdf5oct](https://github.com/gapost/hdf5oct) package) on macOS
(Apple Silicon), including the full interop matrix against the Python
reference implementation on each.

**MATLAB compatibility floor.** The MATLAB-side writer avoids
`h5create`/`h5write`'s `'Datatype', 'string'` option (added around
R2020b) and `arguments` blocks (R2019b+), using the low-level
`H5F`/`H5D`/`H5T`/`H5S`/`H5G`/`H5O`/`H5A`/`H5P` API instead wherever the
high-level functions are insufficient — including for every
`__pytype__`/`dtype` attribute write, since R2019b's `h5writeatt`
defaults to a *fixed-length ASCII* string attribute, which h5py reads
back as raw `bytes` rather than `str` and silently breaks every
type-tag comparison downstream (R2026a's `h5writeatt` already defaults
to the variable-length UTF-8 encoding h5py expects; this only bit
R2019b). Believed to work back to roughly R2011a, when the low-level
interface was introduced, but only R2019b and R2026a have actually been
tested — if you hit an issue on another release, please report it.

## Installation

Add the `tome/` directory to your MATLAB/Octave path:

```matlab
addpath('/path/to/tome-matlab/tome');
```

Octave additionally requires the `hdf5oct` package (MATLAB ships HDF5
support built in):

```octave
pkg install -forge hdf5oct
pkg load hdf5oct
```

## Usage

```matlab
data.run_id = 4;
data.passed = true;
data.note = 'ok';
data.sweep = linspace(0, 1, 1001);
data.labels = {'cold', 'warm', 'hot'};
data.settings = struct('gain', 2.5, 'mode', 'auto');
data.events = {struct('t', 0.1, 'kind', 'start'), ...
               struct('t', 9.4, 'kind', 'stop')};

ok = tomeWrite(data, 'run4.tome');

restored = tomeRead('run4.tome');
```

Both functions signal failure by return value rather than by raising
(mirroring the Python `dict_to_tome`/`tome_to_dict` convention):
`tomeWrite` returns `false` on any write error (and emits a `warning`
with detail), and `tomeRead` returns `[]` if the file cannot be opened
or parsed.

### A list of dicts as the root

```matlab
records = cell(1, 100);
for i = 1:100
    records{i} = struct('i', i - 1, 'sq', (i - 1)^2);
end
tomeWrite(records, 'records.tome');

back = tomeRead('records.tome');   % -> 1x100 cell array of structs
```

A non-scalar `struct` array (`S(1)`, `S(2)`, ...) is also accepted as a
list-of-dicts root or field value, as a MATLAB-idiomatic alternative to
a cell array of structs.

## Type mapping

| MATLAB/Octave                                  | tome `__pytype__` | Read back as                          |
|-------------------------------------------------|--------------------|----------------------------------------|
| scalar `struct`, `containers.Map`               | `dict`             | scalar `struct`                        |
| cell array of dict-likes, non-scalar `struct` array | `list_of_dicts` | 1×N cell array of `struct`             |
| cell array of `char`/string scalars              | `list`             | 1×N cell array of `char`               |
| numeric/logical array (vector or N-D, real or complex) | `ndarray`   | numeric/logical/complex array, same shape |
| `char` row vector / scalar string                | `str`              | `char` row vector                      |
| `logical` scalar                                 | `bool`             | `logical` scalar                       |
| numeric scalar (real or complex; any width)      | dtype name / `complex128` | same MATLAB numeric class       |
| anything else (via `jsonencode`)                 | `json`             | whatever `jsondecode` produces         |

Reading is lenient and follows the format's reader algorithm: it
dispatches on the `__pytype__` attribute where present, and falls back
to decoding a dataset natively otherwise, so a tome written by another
implementation (or a plain HDF5 file) stays readable.

## Design notes

- **Row/column-major axis order.** HDF5 stores arrays row-major; MATLAB
  stores them column-major. A plain vector round-trips as a true 1-D
  HDF5 dataset. A matrix or N-D array is written with its dimensions
  reversed and its data fully axis-permuted (a self-inverse transform),
  so a NumPy/h5py reader sees the exact same shape and element-for-
  element values as MATLAB's `size(A)` — no manual transposing needed
  on either side. This was verified empirically against both MATLAB's
  and Octave's HDF5 bindings, which do not behave identically at the
  low level (see below).
- **True scalar datasets.** The tome format requires scalar (0-D)
  dataspaces for `str`/`bool`/number/`json`/complex values. Octave's
  `h5create` produces a true 0-D dataset when given a literal size of
  `1`; real MATLAB's high-level `h5create` never does (it always
  produces a 1-element 1-D dataset), so MATLAB scalars — and complex
  data, which MATLAB's high-level interface doesn't support at all —
  are written via the low-level `H5S`/`H5T`/`H5D` API instead.
- **String lists** are likewise written via the low-level API on
  MATLAB (a true rank-1 vlen-UTF-8 dataset) rather than
  `h5create(..., 'Datatype', 'string')`, since that high-level option
  isn't available on older MATLAB releases (see the compatibility note
  above). Octave has no low-level HDF5 bindings at all (`hdf5oct` only
  wraps the high-level functions), so it always uses the high-level
  path — Octave's is the only place a plain vector datatype can't
  reliably become a true rank-1 dataset (see the shape limitation
  below), and that applies here too.
- **Complex numbers** are stored as the HDF5 compound type `{double r;
  double i;}`, matching h5py's native complex128 mapping, using
  Octave's `Datatype = 'double complex'` support or MATLAB's low-level
  API as appropriate.
- **Booleans** are stored as a plain `int8` 0/1 scalar or array (not
  HDF5's enum-based bool representation) for simplicity and to avoid a
  MATLAB/Octave asymmetry in how `Datatype = 'logical'` is supported.
  A bool *array* written by the Python implementation uses h5py's HDF5
  enum convention (`{FALSE=0, TRUE=1}`) instead; MATLAB's `h5read`
  returns that as a cell array of `'TRUE'`/`'FALSE'` strings rather
  than decoding it, so the reader detects and decodes it explicitly
  (Octave's `h5read` already decodes it to `logical` natively).
- **Type-tag attributes** (`__pytype__`, `dtype`) are written via the
  low-level `H5A` API on MATLAB rather than `h5writeatt`, for the
  R2019b encoding reason noted in the compatibility floor above.
  `H5O.open` accepts a group or a dataset path identically, so this
  needs no group/dataset branch of its own.

## Limitations

- **Dict keys become HDF5 link names.** Struct field names must be
  valid MATLAB identifiers; this is stricter than the Python
  implementation, which allows any string key. Use `containers.Map` if
  you need a dict with keys that aren't valid identifiers.
- **Octave cannot write an empty dict or empty list-of-dicts.** Octave
  has no low-level HDF5 group-creation API (`hdf5oct` only wraps the
  high-level `h5create`/`h5write`/... functions, which always create a
  dataset), so `tomeWrite` raises a clear error in that one case. Real
  MATLAB (via the low-level `H5G` API) handles it fine.
- **A single-element vector may round-trip as a scalar-shaped
  dataset**, because MATLAB's `h5create` collapses a declared size of
  `1` to a 0-D dataspace — the same mechanism that lets true scalars
  work at all. This only affects a length-1 numeric vector specifically
  (not length-1 string lists, which use a different code path).
- **Under Octave, a MATLAB vector round-trips through tome as an HDF5
  shape `(1, N)` rather than a true rank-1 `(N,)` dataset** (a quirk of
  `hdf5oct`'s `h5create`, which we could not get to produce a true
  rank-1 dataspace for `N > 1`). Values are unaffected — NumPy's
  `.ravel()`/`.tolist()` flatten either way, and this library's own
  reader treats any vector-shaped array as 1-D — but a strict
  shape-based consumer reading an Octave-written tome vector directly
  with h5py will see an extra leading dimension.
- **2-D arrays with a singleton dimension are ambiguous.** MATLAB has
  no distinct 1-D array type, so a MATLAB vector (`isvector` true, e.g.
  size `[1 5]`) is always written as a genuine 1-D dataset. Reading a
  tome written by another implementation with a true 2-D shape like
  `(1, 5)` therefore comes back flattened to a 1×5 row vector rather
  than preserving the 2-D shape — the same ambiguity the Python
  implementation documents for string arrays, generalized here to all
  numeric 2-D arrays with a size-1 dimension.
- **No `bytes` support**, **no streaming/chunking/compression**, and
  **no append/partial read/write** — same as the Python implementation.
- Everything else the [format specification](../stardust/docs/tome/format.md)
  documents as a Python-side limitation (tuples becoming lists, numeric
  lists losing their exact width unless written as an array, an empty
  list being untyped, etc.) applies here too, since it's inherent to the
  on-disk format rather than to any one implementation.

## graf

`graf/` is a MATLAB/Octave reader/writer for [GrAF](../graf), a
self-describing figure archive format built directly on tome: a `.graf`
file is nothing but a tome holding a large, deeply nested struct (dicts
of dicts keyed by axis/trace/surface name, a list-of-dicts save
history, tuples-as-arrays for colors, ...). It's included in this repo
(rather than a separate `graf-matlab` package) specifically to avoid a
second MATLAB dependency footprint, and doubles as a real-world stress
test of the tome library above — it round-trips against the actual
Python `graf` package's own `Graf` class, not just `tome_to_dict`.

```matlab
addpath('tome'); addpath('graf');

g = grafNew('Description', 'demo');
g.supertitle = 'My Figure';
ax = grafNewAxis();
ax.title = 'Axis 1';
tr = grafNewTrace();
tr.x_data = linspace(0, 10, 50);
tr.y_data = sin(tr.x_data);
ax.traces.Tr0 = tr;
g.axes.Ax0 = ax;

writegraf(g, 'demo.graf');
back = readgraf('demo.graf');
```

MATLAB additionally gets figure↔struct translation, and one-step
figure↔file convenience functions mirroring Python's `save_graf`/
`load_graf`:

```matlab
fig = figure; plot(1:10, sin(1:10));

g = fig2graf(fig);             % extract a GrAF struct from a figure
writegraf(g, 'demo.graf');
fig2 = graf2fig(readgraf('demo.graf'));   % and reconstruct one

% ...or in one step:
savegraf(fig, 'demo.graf');    % figure -> struct -> file
fig3 = loadgraf('demo.graf');  % file -> struct -> figure
```

### API

Naming mirrors the Python `graf` package: `write_graf`/`read_graf` move
a `Graf` object to/from a file, `save_graf`/`load_graf` move a
matplotlib figure to/from a file in one step. The MATLAB/Octave
equivalents use `2`/`To`/`From` for direction, per MATLAB convention.

- `grafNew`, `grafNewAxis`, `grafNewTrace`, `grafNewSurface` —
  default-populated structs matching each Python class's own defaults
  (`graf.base.Graf()`, `Axis()`, `Trace()`, `Surface()`). Cross-platform.
  (`grafNewScale`/`grafNewFont`/`grafNewGraphStyle`/`grafNewMetaInfo`
  build the corresponding nested sub-structs but are graf-internal —
  `grafNewAxis`/`grafNew` already populate them with working defaults,
  so there's normally no need to call them directly.)
- `writegraf(g, filename, ...)` / `readgraf(filename)` — the tome-backed
  I/O, directly analogous to `tomeWrite`/`tomeRead` (mirrors Python's
  `write_graf`/`read_graf`). Cross-platform. `writegraf` stamps
  `g.info.provenance` (once) and appends a `g.info.history` entry on
  every call, mirroring Python's `Graf.write_graf` choke point.
- `fig2graf(fig)` / `graf2fig(g, ...)` — figure↔struct translation.
  **MATLAB-only** (see below). Supports 2-D/3-D line plots, scatter,
  error bars, dual y-axes (`yyaxis`), subplot grids with arbitrary
  spans (inferred from on-figure bounding boxes, matching how Python's
  `Graf.mimic`/`to_fig` size their `GridSpec`), and surface/image plots
  (`surf`/`pcolor`/`imagesc`).
- `savegraf(fig, filename, ...)` / `loadgraf(filename, ...)` — one-step
  figure↔file convenience (mirrors Python's `save_graf`/`load_graf`):
  `savegraf` = `fig2graf` + `writegraf`, `loadgraf` = `readgraf` +
  `graf2fig`. `savegraf` also accepts a `.fig` file path in place of a
  handle (via `openfig`), or no figure argument at all (defaults to
  `gcf`). **MATLAB-only**, for the same reason as `fig2graf`/`graf2fig`.

### Design notes / limitations

- **`fig2graf`/`graf2fig` (and therefore `savegraf`/`loadgraf`) are
  MATLAB-only.** Octave's graphics handles are plain numeric HG1-style
  handles with no dot-notation property access, no `yyaxis`, and a
  different Legend/ColorBar/ErrorBar class hierarchy than MATLAB's HG2
  objects — porting the figure-introspection layer would be a largely
  separate, substantial rewrite orthogonal to testing tome/graf
  serialization, which is what this exercise is actually for.
  `writegraf`/`readgraf` work identically on both platforms.
- **A yyaxis trace's side is inferred by color-matching**, since a
  MATLAB `Line` object carries no direct back-reference to which
  `yyaxis` side created it: `fig2graf` compares each line's color
  against `ax.YAxis(2).Color`. An unusual custom color on a right-side
  trace can defeat this heuristic and misclassify it as left-side.
- **Octave cannot save an axis with zero traces AND zero surfaces**
  (or a graf with zero axes) **as a strict, fully Python-compatible
  `.graf` file.** This is the single-purpose-axis case — a line-only or
  surface-only axis always has one of its two dict fields empty — which
  runs straight into tome's "Octave can't write an empty dict" limit
  (see above). Since this is the *common* case for GrAF specifically
  (not an edge case), `writegraf` handles it explicitly rather than just
  erroring: under Octave it omits the empty field with a `warning()`
  instead of writing it, and `readgraf` fills any omitted
  `axes`/`traces`/`surfaces` field back in as empty on read — so
  round-tripping through this library (either platform, either
  direction) is always fully robust. The one real consequence: an
  Octave-written `.graf` file with such an axis is **not** fully
  readable by Python's raw `Graf().read_graf()`, because
  `graf.base.Packable.unpack()` does not tolerate a missing
  dict-manifest key and raises for that axis (verified directly in
  `tests/interop/check_matlab_grafs.py`, which reads Octave-written
  files via `stardust.tome.tome_to_dict` instead and separately confirms
  the `Graf.read_graf()` failure reproduces, so this stays visible
  rather than silently masked). Fixing that root cause is a change to
  the separate `graf` Python package, out of scope here.
- **A python-authored color tuple round-trips as a MATLAB column
  vector, not a row.** `line_color`/`marker_color`/etc. are Python
  tuples, which tome's writer has no dedicated type for and falls back
  to JSON-encoding; `jsondecode` hands a JSON array back as a column
  vector in MATLAB, unlike the row vectors `grafNew*`/`fig2graf` use
  natively. Harmless — `graf2fig` already flattens defensively
  (`(:)'`) before using any color field — but worth knowing if you
  compare a loaded color field against a literal `[r g b]`.
- Everything under tome's own Limitations section above (struct field
  names, numeric width round-tripping, etc.) applies here too, since
  GrAF is just a tome document.

## Tests

- `tests/matlab/TestTomeRoundtrip.m` — a `matlab.unittest` suite
  covering the type mapping, edge cases, and error handling, entirely
  within MATLAB. Run with:
  ```matlab
  addpath('tome');
  results = runtests('tests/matlab/TestTomeRoundtrip');
  ```
- `tests/octave/run_octave_tests.m` — the same cases as an
  assertion-based script, since Octave has no `matlab.unittest`. Also
  runs fine under MATLAB as a lighter-weight alternative. Run with:
  ```
  octave --no-gui --eval "addpath('tests/octave'); run_octave_tests"
  ```
- `tests/interop/` — cross-language round-trip tests against the
  Python reference implementation: Python writes reference tomes that
  MATLAB and Octave read and verify, and MATLAB/Octave write reference
  tomes that Python reads and verifies. Run the whole matrix with:
  ```bash
  STARDUST_PATH=/path/to/stardust MATLAB_BIN=/path/to/matlab \
      tests/interop/run_interop_tests.sh
  ```
  (`STARDUST_PATH` defaults to `../stardust` next to this repo,
  `MATLAB_BIN` to `matlab` on `PATH`; Octave/MATLAB legs are skipped
  automatically if not found.)

graf has the same three-tier structure, one level up the stack:

- `tests/matlab/TestGrafRoundtrip.m` — `matlab.unittest` suite covering
  `grafNew*`/`writegraf`/`readgraf`, plus `fig2graf`/`graf2fig` and the
  one-step `savegraf`/`loadgraf` on real figures (line plots, subplot
  grids with spans, dual y-axes, surfaces) since those are MATLAB-only.
- `tests/octave/run_graf_octave_tests.m` — the serialization-layer
  cases only (`grafNew*`/`writegraf`/`readgraf`), matching the
  MATLAB-only scope of the figure-translation functions.
- `tests/interop/run_graf_interop_tests.sh` — the same 4-leg matrix as
  tome's, but against the real Python `graf` package (`Graf().mimic()`
  from an actual matplotlib figure, `Graf().write_graf()`/`read_graf()`
  — not just `tome_to_dict`). Run with:
  ```bash
  GRAF_PATH=/path/to/graf/src STARDUST_PATH=/path/to/stardust \
      MATLAB_BIN=/path/to/matlab tests/interop/run_graf_interop_tests.sh
  ```
  (`GRAF_PATH` defaults to `../graf/src` next to this repo.)
