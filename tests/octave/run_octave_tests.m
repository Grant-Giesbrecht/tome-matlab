function run_octave_tests()
%RUN_OCTAVE_TESTS Assertion-based test runner for the tome library,
%   covering the same cases as tests/matlab/TestTomeRoundtrip.m. Octave
%   has no matlab.unittest, so this is a plain script using assert().
%   Works under MATLAB too, as a lighter-weight alternative.
%
%   Run with: octave --no-gui -eval "run_octave_tests"

    if exist('OCTAVE_VERSION', 'builtin')
        pkg load hdf5oct;
    end

    here = fileparts(mfilename('fullpath'));
    addpath(fullfile(here, '..', '..', 'tome'));

    workDir = tempname();
    mkdir(workDir);
    cleanupObj = onCleanup(@() rmdirSafe(workDir));

    tests = { ...
        @scalarString, @scalarBool, @scalarNumbers, @scalarComplex, ...
        @numericVector, @numericMatrix2D, @numericArrayND, ...
        @logicalArray, @complexArray, @emptyArray, @stringList, ...
        @nestedDict, @listOfDictsFromCell, @listOfDictsFromStructArray, ...
        @rootIsListOfDicts, @containersMapAsDict, @jsonFallback, ...
        @worstCaseExample, @invalidRootErrorsGracefully, ...
        @readMissingFileReturnsEmpty, @overwriteTruncatesPreviousContent};

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
        error('run_octave_tests:failures', '%d test(s) failed', nFail);
    end
end

function rmdirSafe(d)
    if exist(d, 'dir')
        rmdir(d, 's');
    end
end

function f = tomeFile(workDir, name)
    f = fullfile(workDir, [name '.tome']);
end

function scalarString(workDir)
    f = tomeFile(workDir, 'str');
    data = struct('note', 'hello world', 'empty_str', '');
    assert(tomeWrite(data, f));
    back = tomeRead(f);
    assert(strcmp(back.note, 'hello world'));
    assert(strcmp(back.empty_str, ''));
end

function scalarBool(workDir)
    f = tomeFile(workDir, 'bool');
    data = struct('t', true, 'f', false);
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(islogical(back.t) && back.t == true);
    assert(islogical(back.f) && back.f == false);
end

function scalarNumbers(workDir)
    f = tomeFile(workDir, 'nums');
    data = struct('d', 3.14159, 's', single(2.5), 'i8', int8(-12), ...
        'i16', int16(-1234), 'i32', int32(-123456), ...
        'i64', int64(-123456789012), 'u8', uint8(200), ...
        'u16', uint16(50000), 'u32', uint32(3e9), 'u64', uint64(12345678901234));
    tomeWrite(data, f);
    back = tomeRead(f);
    fields = fieldnames(data);
    for i = 1:numel(fields)
        k = fields{i};
        assert(strcmp(class(back.(k)), class(data.(k))), ['class mismatch: ' k]);
        assert(back.(k) == data.(k), ['value mismatch: ' k]);
    end
end

function scalarComplex(workDir)
    f = tomeFile(workDir, 'complex');
    data = struct('z', 3.5 - 2.25i, 'zr', complex(1, 0));
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(back.z == 3.5 - 2.25i);
    assert(back.zr == complex(1, 0));
end

function numericVector(workDir)
    f = tomeFile(workDir, 'vec');
    data = struct('sweep', linspace(0, 1, 11));
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(max(abs(back.sweep - data.sweep)) < 1e-12);
end

function numericMatrix2D(workDir)
    f = tomeFile(workDir, 'mat2d');
    data = struct('m', reshape(1:12, [3, 4]));
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(isequal(back.m, double(data.m)));
    assert(isequal(size(back.m), [3, 4]));
end

function numericArrayND(workDir)
    f = tomeFile(workDir, 'mat3d');
    data = struct('a', reshape(1:60, [3, 4, 5]));
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(isequal(back.a, double(data.a)));
    assert(isequal(size(back.a), [3, 4, 5]));
end

function logicalArray(workDir)
    f = tomeFile(workDir, 'logicarr');
    data = struct('mask', [true false true; false false true]);
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(isequal(back.mask, data.mask));
    assert(islogical(back.mask));
end

function complexArray(workDir)
    f = tomeFile(workDir, 'complexarr');
    data = struct('z', [1+2i, 3-4i, 5+6i], ...
                   'zm', reshape((1:6) + 1i*(6:-1:1), [2, 3]));
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(isequal(back.z, data.z));
    assert(isequal(back.zm, data.zm));
end

function emptyArray(workDir)
    f = tomeFile(workDir, 'emptyarr');
    data = struct('e', []);
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(isequal(back.e, []));
end

function stringList(workDir)
    f = tomeFile(workDir, 'strlist');
    data = struct('labels', {{'cold', 'warm', 'hot'}});
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(isequal(back.labels, {'cold', 'warm', 'hot'}));
end

function nestedDict(workDir)
    f = tomeFile(workDir, 'nested');
    data.settings = struct('gain', 2.5, 'mode', 'auto');
    data.deep.deeper.deepest = 'found it';
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(back.settings.gain == 2.5);
    assert(strcmp(back.settings.mode, 'auto'));
    assert(strcmp(back.deep.deeper.deepest, 'found it'));
end

function listOfDictsFromCell(workDir)
    f = tomeFile(workDir, 'lod_cell');
    data.events = {struct('t', 0.1, 'kind', 'start'), ...
                   struct('t', 9.4, 'kind', 'stop')};
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(numel(back.events) == 2);
    assert(back.events{1}.t == 0.1);
    assert(strcmp(back.events{1}.kind, 'start'));
    assert(back.events{2}.t == 9.4);
end

function listOfDictsFromStructArray(workDir)
    f = tomeFile(workDir, 'lod_structarray');
    S(1) = struct('i', 0, 'sq', 0);
    S(2) = struct('i', 1, 'sq', 1);
    S(3) = struct('i', 2, 'sq', 4);
    data = struct('records', {{}});
    data.records = S;
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(numel(back.records) == 3);
    assert(back.records{3}.sq == 4);
end

function rootIsListOfDicts(workDir)
    f = tomeFile(workDir, 'root_lod');
    records = cell(1, 100);
    for i = 1:100
        records{i} = struct('i', i - 1, 'sq', (i - 1)^2);
    end
    tomeWrite(records, f);
    back = tomeRead(f);
    assert(numel(back) == 100);
    assert(back{1}.i == 0);
    assert(back{100}.sq == 99^2);
    assert(back{11}.i == 10);
end

function containersMapAsDict(workDir)
    f = tomeFile(workDir, 'map');
    m = containers.Map();
    m('alpha') = 1.5;
    m('beta') = 'text';
    data = struct('cfg', m);
    tomeWrite(data, f);
    back = tomeRead(f);
    assert(back.cfg.alpha == 1.5);
    assert(strcmp(back.cfg.beta, 'text'));
end

function jsonFallback(workDir)
    f = tomeFile(workDir, 'jsonfallback');
    data.mixed = {1, 'a', true};
    tomeWrite(data, f);
    back = tomeRead(f);
    m = reshape(back.mixed, 1, []);
    assert(m{1} == 1 && strcmp(m{2}, 'a') && m{3} == true);
end

function worstCaseExample(workDir)
    f = tomeFile(workDir, 'worked_example');
    data = struct();
    data.run_id = int64(4);
    data.passed = true;
    data.note = 'ok';
    data.sweep = [0.0, 0.5, 1.0];
    data.labels = {'cold', 'hot'};
    data.settings = struct('gain', 2.5);
    data.events = {struct('t', 0.1), struct('t', 9.4)};

    assert(tomeWrite(data, f));
    back = tomeRead(f);

    assert(back.run_id == 4);
    assert(back.passed == true);
    assert(strcmp(back.note, 'ok'));
    assert(isequal(back.sweep, [0.0, 0.5, 1.0]));
    assert(isequal(back.labels, {'cold', 'hot'}));
    assert(back.settings.gain == 2.5);
    assert(back.events{1}.t == 0.1);
    assert(back.events{2}.t == 9.4);
end

function invalidRootErrorsGracefully(workDir)
    f = tomeFile(workDir, 'invalid_root');
    ok = tomeWrite(42, f);
    assert(ok == false);
end

function readMissingFileReturnsEmpty(workDir)
    back = tomeRead(fullfile(workDir, 'does_not_exist.tome'));
    assert(isempty(back));
end

function overwriteTruncatesPreviousContent(workDir)
    f = tomeFile(workDir, 'overwrite');
    tomeWrite(struct('a', 1, 'b', 2), f);
    tomeWrite(struct('c', 3), f);
    back = tomeRead(f);
    assert(~isfield(back, 'a'));
    assert(back.c == 3);
end
