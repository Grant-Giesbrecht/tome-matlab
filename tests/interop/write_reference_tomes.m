function write_reference_tomes(outDir)
%WRITE_REFERENCE_TOMES Write a set of tome files from MATLAB/Octave for
%   the Python side to read back and verify (see check_matlab_tomes.py).
%   Works under both MATLAB and Octave.
    if exist('OCTAVE_VERSION', 'builtin')
        pkg load hdf5oct;
    end

    tagPrefix = 'matlab';
    if exist('OCTAVE_VERSION', 'builtin')
        tagPrefix = 'octave';
    end

    worked.run_id = int64(4);
    worked.passed = true;
    worked.note = 'ok';
    worked.sweep = [0.0, 0.5, 1.0];
    worked.labels = {'cold', 'hot'};
    worked.settings = struct('gain', 2.5);
    worked.events = {struct('t', 0.1), struct('t', 9.4)};
    ok1 = tomeWrite(worked, fullfile(outDir, [tagPrefix '_worked_example.tome']));

    sink.run_id = int32(4);
    sink.passed = true;
    sink.note = 'hello world';
    sink.empty_str = '';
    sink.pi_val = 3.14159;
    sink.z = 3.5 - 2.25i;
    sink.sweep = linspace(0, 1, 11);
    sink.mat = reshape(0:11, [4, 3])';
    sink.big = reshape(1:60, [3, 4, 5]);
    sink.logical_mat = [true false true; false false true];
    sink.zvec = [1+2i, 3-4i, 5+6i];
    sink.labels = {'cold', 'warm', 'hot'};
    sink.empty_list = [];
    sink.settings = struct('gain', 2.5, 'mode', 'auto');
    sink.deep.deeper.deepest = 'found it';
    sink.events = {struct('t', 0.1, 'kind', 'start'), ...
                   struct('t', 9.4, 'kind', 'stop')};
    ok2 = tomeWrite(sink, fullfile(outDir, [tagPrefix '_kitchen_sink.tome']));

    records = cell(1, 100);
    for i = 1:100
        records{i} = struct('i', i - 1, 'sq', (i - 1)^2);
    end
    ok3 = tomeWrite(records, fullfile(outDir, [tagPrefix '_records.tome']));

    assert(ok1 && ok2 && ok3, 'one or more writes failed');
    fprintf('write_reference_tomes (%s): wrote 3 files to %s\n', tagPrefix, outDir);
end
