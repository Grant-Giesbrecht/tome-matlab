function check_python_grafs(dataDir)
%CHECK_PYTHON_GRAFS Read .graf files written by the real Python graf
%   package (gen_reference_grafs.py) and verify them in MATLAB/Octave.
%   Errors (via assert) on any mismatch; prints a line per file on
%   success. Works under both MATLAB and Octave.
    if exist('OCTAVE_VERSION', 'builtin')
        pkg load hdf5oct;
    end

    checkLineTrace(fullfile(dataDir, 'py_line_trace.graf'));
    checkSubplotGrid(fullfile(dataDir, 'py_subplot_grid.graf'));
    checkSurface(fullfile(dataDir, 'py_surface.graf'));

    fprintf('check_python_grafs: all checks passed\n');
end

function checkLineTrace(f)
    g = grafLoad(f);
    assert(strcmp(g.info.description, 'py_line_trace reference'));
    ax0 = g.axes.Ax0;
    assert(strcmp(ax0.title, 'Trig functions'));
    assert(strcmp(ax0.x_axis.label, 'Angle (rad)'));
    assert(ax0.grid_on == true);
    assert(numel(fieldnames(ax0.traces)) == 2);
    tr0 = ax0.traces.Tr0;
    assert(strcmp(tr0.display_name, 'sine'));
    % Python's line_color is a tuple, which tome's writer JSON-encodes
    % (no dedicated tuple type); jsondecode gives a column vector back in
    % MATLAB, vs. the row vectors grafNewTrace/grafFromFig use natively.
    % Harmless — grafToFig already flattens defensively before use.
    assert(isequal(tr0.line_color(:)', [1 0 0]));
    assert(numel(tr0.x_data) == 100);
    tr1 = ax0.traces.Tr1;
    assert(strcmp(tr1.display_name, 'cosine'));
    assert(strcmp(tr1.marker_type, 'o'));
    fprintf('  ok: py_line_trace.graf\n');

    % Must also reconstruct as a figure without erroring (MATLAB only —
    % grafToFig is not available/meaningful under Octave).
    if ~exist('OCTAVE_VERSION', 'builtin')
        fig = grafToFig(g);
        assert(numel(findobj(fig, 'Type', 'axes')) == 1);
        close(fig);
    end
end

function checkSubplotGrid(f)
    g = grafLoad(f);
    assert(strcmp(g.info.description, 'py_subplot_grid reference'));
    assert(numel(fieldnames(g.axes)) == 3);
    assert(isequal(g.axes.Ax0.position, [0 0]));
    assert(isequal(g.axes.Ax0.span, [1 1]));
    assert(isequal(g.axes.Ax1.position, [0 1]));
    assert(g.axes.Ax1.traces.Tr0.has_error_bars == true);
    assert(isequal(g.axes.Ax2.position, [1 0]));
    assert(isequal(g.axes.Ax2.span, [1 2]));
    fprintf('  ok: py_subplot_grid.graf\n');

    if ~exist('OCTAVE_VERSION', 'builtin')
        fig = grafToFig(g);
        assert(numel(findobj(fig, 'Type', 'axes')) == 3);
        close(fig);
    end
end

function checkSurface(f)
    g = grafLoad(f);
    assert(strcmp(g.info.description, 'py_surface reference'));
    ax0 = g.axes.Ax0;
    assert(strcmp(ax0.axis_type, 'AXIS_IMAGE'));
    sfNames = fieldnames(ax0.surfaces);
    assert(numel(sfNames) == 1);
    sf0 = ax0.surfaces.(sfNames{1});
    assert(strcmp(sf0.surf_type, 'SURF_IMAGE'));
    assert(sf0.has_colorbar == true);
    assert(strcmp(sf0.colorbar_label, 'Amplitude'));
    assert(~isempty(sf0.z_grid));
    fprintf('  ok: py_surface.graf\n');

    if ~exist('OCTAVE_VERSION', 'builtin')
        fig = grafToFig(g);
        assert(numel(findobj(fig, 'Type', 'axes')) == 1);
        close(fig);
    end
end
