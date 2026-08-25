function run_graf_octave_tests()
%RUN_GRAF_OCTAVE_TESTS Assertion-based tests for the graf serialization
%   layer (grafNew*/grafSave/grafLoad) under Octave. grafFromFig/grafToFig
%   are MATLAB-only (see grafFromFig.m) so are not exercised here.
%
%   Run with: octave --no-gui -eval "run_graf_octave_tests"

    if exist('OCTAVE_VERSION', 'builtin')
        pkg load hdf5oct;
    end

    here = fileparts(mfilename('fullpath'));
    addpath(fullfile(here, '..', '..', 'tome'));
    addpath(fullfile(here, '..', '..', 'graf'));

    workDir = tempname();
    mkdir(workDir);
    cleanupObj = onCleanup(@() rmdirSafe(workDir));

    tests = {@blankGrafRoundtrip, @fullyPopulatedGrafRoundtrip, ...
             @multipleSavesAppendHistory, @readMissingFileReturnsEmpty};

    nPass = 0;
    nFail = 0;
    for i = 1:numel(tests)
        fn = tests{i};
        name = func2str(fn);
        try
            fn(workDir);
            fprintf('PASS  %s\n', name);
            nPass = nPass + 1;
        catch err
            fprintf('FAIL  %s: %s\n', name, err.message);
            nFail = nFail + 1;
        end
    end

    fprintf('\n%d passed, %d failed\n', nPass, nFail);
    if nFail > 0
        error('run_graf_octave_tests:failures', '%d test(s) failed', nFail);
    end
end

function rmdirSafe(d)
    if exist(d, 'dir')
        rmdir(d, 's');
    end
end

function f = grafFile(workDir, name)
    f = fullfile(workDir, [name '.graf']);
end

function blankGrafRoundtrip(workDir)
    f = grafFile(workDir, 'blank');
    g = grafNew('Description', 'a blank graf');
    g.axes.Ax0 = grafNewAxis();
    g.axes.Ax0.traces.Tr0 = grafNewTrace();

    assert(grafSave(g, f));
    back = grafLoad(f);
    assert(strcmp(back.info.description, 'a blank graf'));
    assert(isequal(back.axes.Ax0.traces.Tr0.line_color, [1 0 0]));
    assert(numel(back.info.history) >= 1);
    assert(~isempty(fieldnames(back.info.provenance)));
end

function fullyPopulatedGrafRoundtrip(workDir)
    f = grafFile(workDir, 'full');
    g = grafNew('Description', 'kitchen sink', ...
                'Conditions', struct('temperature_C', 23.5, 'operator', 'gg'));
    g.supertitle = 'Test Figure';

    ax = grafNewAxis();
    ax.title = 'Axis 1';
    ax.grid_on = true;
    ax.x_axis.label = 'Time (s)';
    ax.x_axis.val_min = 0; ax.x_axis.val_max = 10;
    ax.x_axis.tick_list = [0 5 10];
    ax.x_axis.tick_label_list = {'0', '5', '10'};
    ax.y_axis_L.label = 'Voltage (V)';

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
    sf = grafNewSurface();
    [X, Y] = meshgrid(-2:0.5:2, -2:0.5:2);
    sf.x_grid = X; sf.y_grid = Y; sf.z_grid = X .* exp(-X.^2 - Y.^2);
    sf.uniform_grid = true;
    sfax.surfaces.Sf0 = sf;
    g.axes.Ax1 = sfax;

    assert(grafSave(g, f));
    back = grafLoad(f);

    assert(strcmp(back.supertitle, 'Test Figure'));
    assert(back.info.conditions.temperature_C == 23.5);
    assert(strcmp(back.info.conditions.operator, 'gg'));
    assert(strcmp(back.axes.Ax0.title, 'Axis 1'));
    assert(back.axes.Ax0.grid_on == true);
    assert(isequal(back.axes.Ax0.x_axis.tick_label_list, {'0', '5', '10'}));
    assert(max(abs(back.axes.Ax0.traces.Tr0.y_data(:) - tr.y_data(:))) < 1e-12);
    assert(back.axes.Ax0.traces.Tr0.has_error_bars == true);
    assert(strcmp(back.axes.Ax1.axis_type, 'AXIS_SURFACE'));
    assert(isequal(size(back.axes.Ax1.surfaces.Sf0.z_grid), size(sf.z_grid)));
    assert(max(abs(back.axes.Ax1.surfaces.Sf0.z_grid(:) - sf.z_grid(:))) < 1e-12);
end

function multipleSavesAppendHistory(workDir)
    f = grafFile(workDir, 'history');
    g = grafNew();
    g.axes.Ax0 = grafNewAxis();
    g.axes.Ax0.traces.Tr0 = grafNewTrace();

    grafSave(g, f, 'Action', 'created');
    back1 = grafLoad(f);
    assert(numel(back1.info.history) == 1);

    back1.axes.Ax0.title = 'edited';
    grafSave(back1, f, 'Action', 'edited title');
    back2 = grafLoad(f);
    assert(numel(back2.info.history) == 2);
    assert(strcmp(back2.info.history{2}.action, 'edited title'));
    assert(strcmp(back2.info.provenance.created_utc, back1.info.provenance.created_utc));
end

function readMissingFileReturnsEmpty(workDir)
    back = grafLoad(fullfile(workDir, 'does_not_exist.graf'));
    assert(isempty(back));
end
