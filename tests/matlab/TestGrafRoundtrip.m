classdef TestGrafRoundtrip < matlab.unittest.TestCase
    %TESTGRAFROUNDTRIP Unit tests for the graf MATLAB reader/writer,
    %   entirely within MATLAB (no other language involved). This is
    %   also an end-to-end stress test of the tome library, since GrAF's
    %   serialization is nothing but tomeWrite/tomeRead over a large,
    %   deeply nested real-world struct (dicts of dicts keyed by
    %   axis/trace/surface name, a list-of-dicts history, tuples-as-
    %   arrays for colors, ...).
    %
    %   grafFromFig/grafToFig are MATLAB-only (see grafFromFig.m for why)
    %   so they are exercised here, not in the Octave suite.

    properties
        WorkDir
    end

    methods (TestMethodSetup)
        function setupPath(testCase)
            here = fileparts(mfilename('fullpath'));
            addpath(fullfile(here, '..', '..', 'tome'));
            addpath(fullfile(here, '..', '..', 'graf'));
            testCase.WorkDir = tempname();
            mkdir(testCase.WorkDir);
        end
    end

    methods (TestMethodTeardown)
        function teardownWorkDir(testCase)
            if exist(testCase.WorkDir, 'dir')
                rmdir(testCase.WorkDir, 's');
            end
            close all force;
        end
    end

    methods (Access = private)
        function f = grafFile(testCase, name)
            f = fullfile(testCase.WorkDir, [name '.graf']);
        end
    end

    methods (Test)
        function blankGrafRoundtrip(testCase)
            f = testCase.grafFile('blank');
            g = grafNew('Description', 'a blank graf');
            g.axes.Ax0 = grafNewAxis();
            g.axes.Ax0.traces.Tr0 = grafNewTrace();

            testCase.verifyTrue(grafSave(g, f));
            back = grafLoad(f);
            testCase.verifyEqual(back.info.description, 'a blank graf');
            testCase.verifyEqual(back.axes.Ax0.traces.Tr0.line_color, [1 0 0]);
            testCase.verifyGreaterThanOrEqual(numel(back.info.history), 1);
            testCase.verifyNotEmpty(fieldnames(back.info.provenance));
        end

        function fullyPopulatedGrafRoundtrip(testCase)
            f = testCase.grafFile('full');
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
            ax.y_axis_L.val_min = -1; ax.y_axis_L.val_max = 1;
            ax.y_axis_R = grafNewScale();
            ax.y_axis_R.label = 'Current (A)';
            ax.z_axis = grafNewScale('Valid', false);

            tr = grafNewTrace();
            tr.x_data = linspace(0, 10, 50);
            tr.y_data = sin(tr.x_data);
            tr.display_name = 'sine';
            tr.line_color = [0 0.4 0.8];
            tr.marker_type = 'o';
            tr.has_error_bars = true;
            tr.y_err_neg = 0.05 * ones(1, 50);
            tr.y_err_pos = 0.05 * ones(1, 50);
            ax.traces.Tr0 = tr;

            tr2 = grafNewTrace();
            tr2.x_data = linspace(0, 10, 50);
            tr2.y_data = cos(tr2.x_data);
            tr2.use_yaxis_R = true;
            tr2.display_name = 'cosine (right)';
            ax.traces.Tr1 = tr2;

            g.axes.Ax0 = ax;

            sfax = grafNewAxis();
            sfax.axis_type = 'AXIS_SURFACE';
            sf = grafNewSurface();
            [X, Y] = meshgrid(-2:0.5:2, -2:0.5:2);
            sf.x_grid = X; sf.y_grid = Y; sf.z_grid = X .* exp(-X.^2 - Y.^2);
            sf.uniform_grid = true;
            sf.has_colorbar = true;
            sf.colorbar_label = 'Amplitude';
            sf.colorbar_vmin = -0.5;
            sf.colorbar_vmax = 0.5;
            sfax.surfaces.Sf0 = sf;
            g.axes.Ax1 = sfax;

            testCase.verifyTrue(grafSave(g, f));
            back = grafLoad(f);

            testCase.verifyEqual(back.supertitle, 'Test Figure');
            testCase.verifyEqual(back.info.conditions.temperature_C, 23.5);
            testCase.verifyEqual(back.info.conditions.operator, 'gg');
            testCase.verifyEqual(back.axes.Ax0.title, 'Axis 1');
            testCase.verifyTrue(back.axes.Ax0.grid_on);
            testCase.verifyEqual(back.axes.Ax0.x_axis.tick_label_list, {'0', '5', '10'});
            testCase.verifyEqual(back.axes.Ax0.traces.Tr0.y_data, tr.y_data, 'AbsTol', 1e-12);
            testCase.verifyTrue(back.axes.Ax0.traces.Tr0.has_error_bars);
            testCase.verifyTrue(back.axes.Ax0.traces.Tr1.use_yaxis_R);
            testCase.verifyEqual(back.axes.Ax1.axis_type, 'AXIS_SURFACE');
            testCase.verifySize(back.axes.Ax1.surfaces.Sf0.z_grid, size(sf.z_grid));
            testCase.verifyEqual(back.axes.Ax1.surfaces.Sf0.z_grid, sf.z_grid, 'AbsTol', 1e-12);
            testCase.verifyEqual(back.axes.Ax1.surfaces.Sf0.colorbar_vmin, -0.5);
        end

        function multipleSavesAppendHistory(testCase)
            f = testCase.grafFile('history');
            g = grafNew();
            g.axes.Ax0 = grafNewAxis();
            g.axes.Ax0.traces.Tr0 = grafNewTrace();

            grafSave(g, f, 'Action', 'created');
            back1 = grafLoad(f);
            testCase.verifyEqual(numel(back1.info.history), 1);

            back1.axes.Ax0.title = 'edited';
            grafSave(back1, f, 'Action', 'edited title');
            back2 = grafLoad(f);
            testCase.verifyEqual(numel(back2.info.history), 2);
            testCase.verifyEqual(back2.info.history{2}.action, 'edited title');
            % provenance is stamped once and never overwritten
            testCase.verifyEqual(back2.info.provenance.created_utc, back1.info.provenance.created_utc);
        end

        function lineFigureRoundtrip(testCase)
            fig = figure('Visible', 'off');
            x = linspace(0, 2*pi, 100);
            plot(x, sin(x), '-', 'Color', [1 0 0], 'LineWidth', 2, 'DisplayName', 'sine');
            hold on;
            plot(x, cos(x), '--', 'Color', [0 0 1], 'Marker', 'o', 'MarkerSize', 4, 'DisplayName', 'cosine');
            xlabel('Angle (rad)'); ylabel('Value'); title('Trig functions'); grid on;

            g = grafFromFig(fig);
            testCase.verifyEqual(fieldnames(g.axes), {'Ax0'});
            ax0 = g.axes.Ax0;
            testCase.verifyEqual(ax0.title, 'Trig functions');
            testCase.verifyTrue(ax0.grid_on);
            testCase.verifyEqual(numel(fieldnames(ax0.traces)), 2);
            testCase.verifyEqual(ax0.traces.Tr0.display_name, 'sine');
            testCase.verifyEqual(ax0.traces.Tr0.line_color, [1 0 0]);
            testCase.verifyEqual(ax0.traces.Tr1.display_name, 'cosine');
            testCase.verifyEqual(ax0.traces.Tr1.marker_type, 'o');

            f = testCase.grafFile('linefig');
            grafSave(g, f);
            back = grafLoad(f);
            fig2 = grafToFig(back, 'Title', 'Reconstructed');
            axs2 = findobj(fig2, 'Type', 'axes');
            testCase.verifyEqual(numel(axs2), 1);
            lines2 = findobj(axs2(1), 'Type', 'line');
            testCase.verifyEqual(numel(lines2), 2);
        end

        function subplotGridWithSpanRoundtrip(testCase)
            fig = figure('Visible', 'off');
            subplot(2, 2, 1); plot(1:10, (1:10).^2); title('Quadratic');
            subplot(2, 2, 2); errorbar(1:5, [2 4 3 5 4], [0.5 0.3 0.4 0.2 0.3]); title('Errorbar');
            subplot(2, 2, [3 4]); plot(1:10, 1:10); title('Wide');

            g = grafFromFig(fig);
            testCase.verifyEqual(numel(fieldnames(g.axes)), 3);
            testCase.verifyEqual(g.axes.Ax0.position, [0 0]);
            testCase.verifyEqual(g.axes.Ax0.span, [1 1]);
            testCase.verifyEqual(g.axes.Ax1.position, [0 1]);
            testCase.verifyEqual(g.axes.Ax2.position, [1 0]);
            testCase.verifyEqual(g.axes.Ax2.span, [1 2]);
            testCase.verifyTrue(g.axes.Ax1.traces.Tr0.has_error_bars);

            f = testCase.grafFile('subplotgrid');
            grafSave(g, f);
            back = grafLoad(f);
            fig2 = grafToFig(back);
            axs2 = findobj(fig2, 'Type', 'axes');
            testCase.verifyEqual(numel(axs2), 3);
        end

        function dualYAxisRoundtrip(testCase)
            fig = figure('Visible', 'off');
            yyaxis left; plot(1:10, 1:10, '-'); ylabel('Left');
            yyaxis right; plot(1:10, (1:10) * 100, '--'); ylabel('Right');

            g = grafFromFig(fig);
            ax0 = g.axes.Ax0;
            testCase.verifyTrue(ax0.y_axis_R.is_valid);
            testCase.verifyFalse(ax0.traces.Tr0.use_yaxis_R);
            testCase.verifyTrue(ax0.traces.Tr1.use_yaxis_R);

            f = testCase.grafFile('dualaxis');
            grafSave(g, f);
            back = grafLoad(f);
            fig2 = grafToFig(back);
            testCase.verifyEqual(numel(findobj(fig2, 'Type', 'axes')), 1);
        end

        function surfaceFigureRoundtrip(testCase)
            fig = figure('Visible', 'off');
            [X, Y] = meshgrid(-2:0.2:2, -2:0.2:2);
            Z = X .* exp(-X.^2 - Y.^2);
            surf(X, Y, Z);
            colorbar;
            title('Surf');

            g = grafFromFig(fig);
            ax0 = g.axes.Ax0;
            testCase.verifyEqual(ax0.axis_type, 'AXIS_SURFACE');
            sfNames = fieldnames(ax0.surfaces);
            testCase.verifyEqual(numel(sfNames), 1);
            sf0 = ax0.surfaces.(sfNames{1});
            testCase.verifyEqual(sf0.surf_type, 'SURF_SURFACE');
            testCase.verifySize(sf0.z_grid, size(Z));
            testCase.verifyTrue(sf0.has_colorbar);

            f = testCase.grafFile('surffig');
            grafSave(g, f);
            back = grafLoad(f);
            fig2 = grafToFig(back);
            testCase.verifyEqual(numel(findobj(fig2, 'Type', 'axes')), 1);
        end

        function readMissingFileReturnsEmpty(testCase)
            back = grafLoad(fullfile(testCase.WorkDir, 'does_not_exist.graf'));
            testCase.verifyEmpty(back);
        end
    end
end
