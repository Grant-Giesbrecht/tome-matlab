function write_reference_grafs(outDir)
%WRITE_REFERENCE_GRAFS Write reference .graf files from MATLAB/Octave for
%   the Python side to read back with the real graf package and verify
%   (see check_matlab_grafs.py). Works under both MATLAB and Octave;
%   MATLAB additionally exercises fig2graf (Octave has no equivalent
%   here, see fig2graf.m).
    if exist('OCTAVE_VERSION', 'builtin')
        pkg load hdf5oct;
    end
    tagPrefix = 'matlab';
    if exist('OCTAVE_VERSION', 'builtin')
        tagPrefix = 'octave';
    end

    % --- A pure-struct graf, built with the grafNew* constructors -----------
    g = grafNew('Description', [tagPrefix ' kitchen sink reference']);
    g.supertitle = 'Kitchen Sink';

    ax = grafNewAxis();
    ax.title = 'Axis 1';
    ax.grid_on = true;
    ax.x_axis.label = 'Time (s)';
    ax.x_axis.val_min = 0; ax.x_axis.val_max = 10;
    ax.y_axis_L.label = 'Voltage (V)';
    ax.y_axis_L.val_min = -1; ax.y_axis_L.val_max = 1;

    tr = grafNewTrace();
    tr.x_data = linspace(0, 10, 50);
    tr.y_data = sin(tr.x_data);
    tr.display_name = 'sine';
    tr.line_color = [0 0.4 0.8];
    tr.has_error_bars = true;
    tr.y_err_neg = 0.05 * ones(1, 50);
    tr.y_err_pos = 0.05 * ones(1, 50);
    ax.traces.Tr0 = tr;
    g.axes.Ax0 = ax;

    sfax = grafNewAxis();
    sfax.axis_type = 'AXIS_SURFACE';
    sfax.z_axis.is_valid = true;   % AXIS_SURFACE implies a real 3-D z axis (see fig2graf)
    sf = grafNewSurface();
    [X, Y] = meshgrid(-2:0.5:2, -2:0.5:2);
    sf.x_grid = X; sf.y_grid = Y; sf.z_grid = X .* exp(-X.^2 - Y.^2);
    sf.uniform_grid = true;
    sfax.surfaces.Sf0 = sf;
    g.axes.Ax1 = sfax;

    ok1 = writegraf(g, fullfile(outDir, [tagPrefix '_kitchen_sink.graf']));

    ok2 = true;
    if ~exist('OCTAVE_VERSION', 'builtin')
        % --- A real MATLAB figure, extracted via fig2graf -----------------
        fig = figure('Visible', 'off');
        x = linspace(0, 2 * pi, 100);
        plot(x, sin(x), '-', 'Color', [1 0 0], 'LineWidth', 2, 'DisplayName', 'sine');
        hold on;
        plot(x, cos(x), '--', 'Color', [0 0 1], 'Marker', 'o', 'DisplayName', 'cosine');
        xlabel('Angle (rad)'); ylabel('Value'); title('Trig functions'); grid on;

        gfig = fig2graf(fig);
        gfig.info.description = [tagPrefix ' line trace reference'];
        ok2 = writegraf(gfig, fullfile(outDir, [tagPrefix '_line_trace.graf']));
        close(fig);
    end

    assert(ok1 && ok2, 'one or more writes failed');
    fprintf('write_reference_grafs (%s): wrote reference file(s) to %s\n', tagPrefix, outDir);
end
