classdef TestTomeRoundtrip < matlab.unittest.TestCase
    %TESTTOMEROUNDTRIP Unit tests for the tome MATLAB reader/writer.
    %   Exercises tome.write/tome.read round trips entirely within
    %   MATLAB (no other language involved). Run with:
    %       results = runtests('TestTomeRoundtrip');

    properties
        WorkDir
    end

    methods (TestMethodSetup)
        function setupPath(testCase)
            here = fileparts(mfilename('fullpath'));
            addpath(fullfile(here, '..', '..', 'tome'));
            testCase.WorkDir = tempname();
            mkdir(testCase.WorkDir);
        end
    end

    methods (TestMethodTeardown)
        function teardownWorkDir(testCase)
            if exist(testCase.WorkDir, 'dir')
                rmdir(testCase.WorkDir, 's');
            end
        end
    end

    methods (Access = private)
        function f = tomeFile(testCase, name)
            f = fullfile(testCase.WorkDir, [name '.tome']);
        end
    end

    methods (Test)
        function scalarString(testCase)
            f = testCase.tomeFile('str');
            data = struct('note', 'hello world', 'empty_str', '');
            testCase.verifyTrue(tomeWrite(data, f));
            back = tomeRead(f);
            testCase.verifyEqual(back.note, 'hello world');
            testCase.verifyEqual(back.empty_str, '');
        end

        function scalarBool(testCase)
            f = testCase.tomeFile('bool');
            data = struct('t', true, 'f', false);
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(back.t, true);
            testCase.verifyEqual(back.f, false);
            testCase.verifyClass(back.t, 'logical');
        end

        function scalarNumbers(testCase)
            f = testCase.tomeFile('nums');
            data = struct( ...
                'd', 3.14159, ...
                's', single(2.5), ...
                'i8', int8(-12), ...
                'i16', int16(-1234), ...
                'i32', int32(-123456), ...
                'i64', int64(-123456789012), ...
                'u8', uint8(200), ...
                'u16', uint16(50000), ...
                'u32', uint32(3e9), ...
                'u64', uint64(12345678901234) ...
            );
            tomeWrite(data, f);
            back = tomeRead(f);
            fields = fieldnames(data);
            for i = 1:numel(fields)
                k = fields{i};
                testCase.verifyEqual(back.(k), data.(k));
                testCase.verifyClass(back.(k), class(data.(k)));
            end
        end

        function scalarComplex(testCase)
            f = testCase.tomeFile('complex');
            data = struct('z', 3.5 - 2.25i, 'zr', complex(1, 0));
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(back.z, 3.5 - 2.25i);
            testCase.verifyEqual(back.zr, complex(1, 0));
        end

        function numericVector(testCase)
            f = testCase.tomeFile('vec');
            data = struct('sweep', linspace(0, 1, 11));
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(back.sweep, data.sweep, 'AbsTol', 1e-12);
        end

        function numericMatrix2D(testCase)
            f = testCase.tomeFile('mat2d');
            data = struct('m', reshape(1:12, [3, 4]));
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(back.m, double(data.m));
            testCase.verifySize(back.m, [3, 4]);
        end

        function numericArrayND(testCase)
            f = testCase.tomeFile('mat3d');
            data = struct('a', reshape(1:60, [3, 4, 5]));
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(back.a, double(data.a));
            testCase.verifySize(back.a, [3, 4, 5]);
        end

        function logicalArray(testCase)
            f = testCase.tomeFile('logicarr');
            data = struct('mask', [true false true; false false true]);
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(back.mask, data.mask);
            testCase.verifyClass(back.mask, 'logical');
        end

        function complexArray(testCase)
            f = testCase.tomeFile('complexarr');
            data = struct('z', [1+2i, 3-4i, 5+6i], ...
                           'zm', reshape((1:6) + 1i*(6:-1:1), [2, 3]));
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(back.z, data.z);
            testCase.verifyEqual(back.zm, data.zm);
        end

        function emptyArray(testCase)
            f = testCase.tomeFile('emptyarr');
            data = struct('e', []);
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(back.e, []);
        end

        function stringList(testCase)
            f = testCase.tomeFile('strlist');
            data = struct('labels', {{'cold', 'warm', 'hot'}});
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(back.labels, {'cold', 'warm', 'hot'});
        end

        function nestedDict(testCase)
            f = testCase.tomeFile('nested');
            data.settings = struct('gain', 2.5, 'mode', 'auto');
            data.deep.deeper.deepest = 'found it';
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(back.settings.gain, 2.5);
            testCase.verifyEqual(back.settings.mode, 'auto');
            testCase.verifyEqual(back.deep.deeper.deepest, 'found it');
        end

        function listOfDictsFromCell(testCase)
            f = testCase.tomeFile('lod_cell');
            data.events = {struct('t', 0.1, 'kind', 'start'), ...
                           struct('t', 9.4, 'kind', 'stop')};
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(numel(back.events), 2);
            testCase.verifyEqual(back.events{1}.t, 0.1);
            testCase.verifyEqual(back.events{1}.kind, 'start');
            testCase.verifyEqual(back.events{2}.t, 9.4);
        end

        function listOfDictsFromStructArray(testCase)
            f = testCase.tomeFile('lod_structarray');
            S(1) = struct('i', 0, 'sq', 0);
            S(2) = struct('i', 1, 'sq', 1);
            S(3) = struct('i', 2, 'sq', 4);
            data = struct('records', {{}});
            data.records = S;
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(numel(back.records), 3);
            testCase.verifyEqual(back.records{3}.sq, 4);
        end

        function rootIsListOfDicts(testCase)
            f = testCase.tomeFile('root_lod');
            records = cell(1, 100);
            for i = 1:100
                records{i} = struct('i', i - 1, 'sq', (i - 1)^2);
            end
            tomeWrite(records, f);
            back = tomeRead(f);
            testCase.verifyEqual(numel(back), 100);
            testCase.verifyEqual(back{1}.i, 0);
            testCase.verifyEqual(back{100}.sq, 99^2);
            % Index ordering must be numeric, not lexicographic (10 before 2).
            testCase.verifyEqual(back{11}.i, 10);
        end

        function containersMapAsDict(testCase)
            f = testCase.tomeFile('map');
            m = containers.Map();
            m('alpha') = 1.5;
            m('beta') = 'text';
            data = struct('cfg', m);
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(back.cfg.alpha, 1.5);
            testCase.verifyEqual(back.cfg.beta, 'text');
        end

        function jsonFallback(testCase)
            f = testCase.tomeFile('jsonfallback');
            data = struct('pair', {{1, 2}});
            % A struct array is handled as list_of_dicts, but a plain cell
            % mixing types has no dedicated tome branch and falls back to
            % JSON encoding of the whole value.
            data.mixed = {1, 'a', true};
            tomeWrite(data, f);
            back = tomeRead(f);
            testCase.verifyEqual(reshape(back.mixed, 1, []), {1, 'a', true});
        end

        function worstCaseExample(testCase)
            % Mirrors the worked example in the format specification.
            f = testCase.tomeFile('worked_example');
            data = struct();
            data.run_id = int64(4);
            data.passed = true;
            data.note = 'ok';
            data.sweep = [0.0, 0.5, 1.0];
            data.labels = {'cold', 'hot'};
            data.settings = struct('gain', 2.5);
            data.events = {struct('t', 0.1), struct('t', 9.4)};

            testCase.verifyTrue(tomeWrite(data, f));
            back = tomeRead(f);

            testCase.verifyEqual(back.run_id, int64(4));
            testCase.verifyEqual(back.passed, true);
            testCase.verifyEqual(back.note, 'ok');
            testCase.verifyEqual(back.sweep, [0.0, 0.5, 1.0]);
            testCase.verifyEqual(back.labels, {'cold', 'hot'});
            testCase.verifyEqual(back.settings.gain, 2.5);
            testCase.verifyEqual(back.events{1}.t, 0.1);
            testCase.verifyEqual(back.events{2}.t, 9.4);
        end

        function invalidRootErrorsGracefully(testCase)
            f = testCase.tomeFile('invalid_root');
            ok = tomeWrite(42, f);
            testCase.verifyFalse(ok);
        end

        function readMissingFileReturnsEmpty(testCase)
            back = tomeRead(fullfile(testCase.WorkDir, 'does_not_exist.tome'));
            testCase.verifyEmpty(back);
        end

        function overwriteTruncatesPreviousContent(testCase)
            f = testCase.tomeFile('overwrite');
            tomeWrite(struct('a', 1, 'b', 2), f);
            tomeWrite(struct('c', 3), f);
            back = tomeRead(f);
            testCase.verifyFalse(isfield(back, 'a'));
            testCase.verifyEqual(back.c, 3);
        end
    end
end
