function check_python_tomes(dataDir)
%CHECK_PYTHON_TOMES Read tome files written by Python (stardust.tome)
%   and verify they come back correctly in MATLAB/Octave. Errors (via
%   assert) on any mismatch; prints a line per file on success.
%   Works under both MATLAB and Octave.
    if exist('OCTAVE_VERSION', 'builtin')
        pkg load hdf5oct;
    end

    checkWorkedExample(fullfile(dataDir, 'py_worked_example.tome'));
    checkKitchenSink(fullfile(dataDir, 'py_kitchen_sink.tome'));
    checkRecords(fullfile(dataDir, 'py_records.tome'));

    fprintf('check_python_tomes: all checks passed\n');
end

function checkWorkedExample(f)
    d = tomeRead(f);
    assert(d.run_id == 4);
    assert(islogical(d.passed) && d.passed == true);
    assert(strcmp(d.note, 'ok'));
    assert(isequal(d.sweep, [0.0, 0.5, 1.0]));
    assert(isequal(d.labels, {'cold', 'hot'}));
    assert(isequal(reshape(d.mixed, 1, []), {1, 'a', []}));
    assert(isequal(d.nothing, []));
    assert(d.settings.gain == 2.5);
    assert(numel(d.events) == 2);
    assert(d.events{1}.t == 0.1);
    assert(d.events{2}.t == 9.4);
    fprintf('  ok: py_worked_example.tome\n');
end

function checkKitchenSink(f)
    d = tomeRead(f);
    assert(d.run_id == 4);
    assert(d.passed == true);
    assert(strcmp(d.note, 'hello world'));
    assert(strcmp(d.empty_str, ''));
    assert(abs(d.pi_val - 3.14159) < 1e-9);
    assert(abs(d.z - (3.5 - 2.25i)) < 1e-9);
    assert(isequal(size(d.sweep), [1, 11]));
    assert(max(abs(d.sweep - linspace(0, 1, 11))) < 1e-12);
    assert(isequal(size(d.mat), [3, 4]));
    assert(isequal(d.mat, reshape(0:11, [4, 3])'));
    assert(isequal(size(d.big), [3, 4, 5]));
    assert(d.big(1, 1, 1) == 1);
    assert(d.big(3, 4, 5) == 60);
    assert(islogical(d.logical_mat));
    assert(isequal(d.logical_mat, logical([1 0 1; 0 0 1])));
    assert(isequal(d.zvec, [1+2i, 3-4i, 5+6i]));
    assert(isequal(d.labels, {'cold', 'warm', 'hot'}));
    assert(isequal(d.empty_list, []));
    assert(d.settings.gain == 2.5 && strcmp(d.settings.mode, 'auto'));
    assert(strcmp(d.deep.deeper.deepest, 'found it'));
    assert(numel(d.events) == 2);
    assert(strcmp(d.events{1}.kind, 'start'));
    assert(strcmp(d.events{2}.kind, 'stop'));
    fprintf('  ok: py_kitchen_sink.tome\n');
end

function checkRecords(f)
    d = tomeRead(f);
    assert(numel(d) == 100);
    assert(d{1}.i == 0 && d{1}.sq == 0);
    assert(d{11}.i == 10 && d{11}.sq == 100);
    assert(d{100}.i == 99 && d{100}.sq == 99 * 99);
    fprintf('  ok: py_records.tome\n');
end
