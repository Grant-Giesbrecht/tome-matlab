function g = grafFromFig(fig)
%GRAFFROMFIG Extract a GrAF struct from a MATLAB figure handle.
%
%   g = grafFromFig(fig)
%   g = grafFromFig()          % uses gcf
%
%   Returns a struct compatible with grafSave/grafLoad/grafToFig.
%   Supports line plots (2-D and 3-D), scatter, error bars, dual y-axes
%   (yyaxis), and surface/image plots (surf/pcolor/imagesc).
%
%   Known limitations (see README): a trace plotted on the right-hand
%   side of a yyaxis pair is identified by matching its color against
%   ax.YAxis(2).Color, since MATLAB Line objects carry no direct
%   back-reference to which yyaxis side created them — an unusual custom
%   color on such a trace can defeat this heuristic.
%
%   MATLAB-only. Octave's graphics handles are plain numeric HG1-style
%   handles (no dot-notation property access, no yyaxis, a different
%   Legend/ColorBar/ErrorBar class hierarchy), which this function relies
%   on throughout; grafSave/grafLoad (the tome-backed serialization) work
%   identically on both platforms and are what to use from Octave.
    if nargin < 1 || isempty(fig)
        fig = gcf;
    end

    g = grafNew();

    st = findobj(fig, 'Type', 'text', '-and', 'Tag', 'sgtitle');
    if ~isempty(st)
        g.supertitle = char(st(1).String);
    else
        try
            st_str = fig.SuptitleText.String;
            if ~isempty(st_str)
                g.supertitle = char(st_str);
            end
        catch
        end
    end

    origUnits = fig.Units;
    fig.Units = 'inches';
    sz = fig.Position;
    fig.Units = origUnits;
    cm_per_inch = 2.54;
    g.fig_width_cm  = sz(3) * cm_per_inch;
    g.fig_height_cm = sz(4) * cm_per_inch;

    allAxes = findobj(fig, 'Type', 'axes');
    isLegend = arrayfun(@(a) isa(a, 'matlab.graphics.illustration.Legend'), allAxes);
    isColorbar = arrayfun(@(a) isa(a, 'matlab.graphics.illustration.ColorBar'), allAxes);
    allAxes = allAxes(~isLegend & ~isColorbar);
    allAxes = flipud(allAxes);   % so Ax0 is the first-created axes

    if isempty(allAxes)
        return
    end

    positions = grafInferGridPositions(allAxes);

    for ai = 1:numel(allAxes)
        axName = sprintf('Ax%d', ai - 1);
        posSpan = positions(double(allAxes(ai)));
        g.axes.(axName) = grafExtractAxis(allAxes(ai), posSpan);
    end
end

% =============================================================================
function ax_s = grafExtractAxis(ax_h, posSpan)
    ax_s = grafNewAxis();
    ax_s.position = posSpan{1};
    ax_s.span = posSpan{2};
    ax_s.title = char(ax_h.Title.String);
    ax_s.grid_on = strcmp(ax_h.XGrid, 'on');

    hasSurface = ~isempty(findobj(ax_h, 'Type', 'surface')) || ~isempty(findobj(ax_h, 'Type', 'image'));

    if hasSurface
        ax_s = grafExtractSurfaceAxis(ax_h, ax_s);
    else
        ax_s = grafExtractLineAxis(ax_h, ax_s);
    end
end

% -----------------------------------------------------------------------------
% Line / scatter / error-bar axes
% -----------------------------------------------------------------------------
function ax_s = grafExtractLineAxis(ax_h, ax_s)
    ax_s.axis_type = 'AXIS_LINE2D';   % GrAF uses this for 3-D lines too (see z_axis)

    hasRight = numel(ax_h.YAxis) == 2;

    ax_s.x_axis = grafExtractScale(ax_h, 'x');
    if hasRight
        yyaxis(ax_h, 'left');
        ax_s.y_axis_L = grafExtractScale(ax_h, 'y');
        yyaxis(ax_h, 'right');
        ax_s.y_axis_R = grafExtractScale(ax_h, 'y');
        rightColor = ax_h.YAxis(2).Color;
        yyaxis(ax_h, 'left');
    else
        ax_s.y_axis_L = grafExtractScale(ax_h, 'y');
        ax_s.y_axis_R = grafNewScale('Valid', false);
        rightColor = [];
    end

    is3d = ~isempty(findobj(ax_h, 'Type', 'line', '-and', '-function', @(o) ~isempty(o.ZData) && any(o.ZData ~= 0)));
    if is3d
        ax_s.z_axis = grafExtractScale(ax_h, 'z');
    else
        ax_s.z_axis = grafNewScale('Valid', false);
    end

    tr_idx = 0;
    errbarObjs = findobj(ax_h, '-function', @(o) isa(o, 'matlab.graphics.chart.primitive.ErrorBar'));
    for ei = 1:numel(errbarObjs)
        tr = grafExtractErrorbar(errbarObjs(ei), rightColor);
        ax_s.traces.(sprintf('Tr%d', tr_idx)) = tr;
        tr_idx = tr_idx + 1;
    end

    linesAll = flipud(findobj(ax_h, 'Type', 'line'));   % oldest (first-plotted) first
    for li = 1:numel(linesAll)
        ln = linesAll(li);
        if isa(ln.Parent, 'matlab.graphics.chart.primitive.ErrorBar')
            continue
        end
        zvals = ln.ZData;
        if isempty(zvals) || all(zvals == 0)
            tr = grafExtractLine2D(ln, rightColor);
        else
            tr = grafExtractLine3D(ln, rightColor);
        end
        ax_s.traces.(sprintf('Tr%d', tr_idx)) = tr;
        tr_idx = tr_idx + 1;
    end
end

function sc = grafExtractScale(ax_h, whichAxis)
    sc = grafNewScale();
    switch whichAxis
        case 'x'
            sc.label = char(ax_h.XLabel.String);
            lim = ax_h.XLim;
            ticks = ax_h.XTick;
            tickLabels = ax_h.XTickLabel;
            sc.scale_type = char(ax_h.XScale);
        case 'y'
            sc.label = char(ax_h.YLabel.String);
            lim = ax_h.YLim;
            ticks = ax_h.YTick;
            tickLabels = ax_h.YTickLabel;
            sc.scale_type = char(ax_h.YScale);
        case 'z'
            sc.label = char(ax_h.ZLabel.String);
            lim = ax_h.ZLim;
            ticks = ax_h.ZTick;
            tickLabels = ax_h.ZTickLabel;
            try
                sc.scale_type = char(ax_h.ZScale);
            catch
                sc.scale_type = 'linear';
            end
    end
    sc.val_min = lim(1);
    sc.val_max = lim(2);
    sc.tick_list = ticks(:)';
    if ischar(tickLabels)
        sc.tick_label_list = {tickLabels};
    elseif iscell(tickLabels)
        sc.tick_label_list = tickLabels(:)';
    else
        sc.tick_label_list = {};
    end
    sc.minor_tick_list = [];
end

function tr = grafExtractLine2D(ln, rightColor)
    tr = grafNewTrace();
    tr.trace_type = 'TRACE_LINE2D';
    tr.display_name = char(ln.DisplayName);
    tr.x_data = double(ln.XData(:))';
    tr.y_data = double(ln.YData(:))';
    tr.z_data = [];

    tr.line_type = grafLineStyleToGraf(ln.LineStyle);
    tr.line_width = ln.LineWidth;
    tr.line_color = double(ln.Color(1:3));

    tr.marker_type = grafMarkerToGraf(ln.Marker);
    tr.marker_size = ln.MarkerSize;
    mfc = ln.MarkerFaceColor;
    if ischar(mfc)
        tr.marker_color = tr.line_color;
    else
        tr.marker_color = double(mfc(1:3));
    end

    tr.alpha = 1.0;
    tr.use_yaxis_R = grafColorMatches(tr.line_color, rightColor);
end

function tr = grafExtractLine3D(ln, rightColor)
    tr = grafExtractLine2D(ln, rightColor);
    tr.trace_type = 'TRACE_LINE3D';
    tr.z_data = double(ln.ZData(:))';
end

function tr = grafExtractErrorbar(eb, rightColor)
    tr = grafNewTrace();
    tr.trace_type = 'TRACE_LINE2D';
    tr.display_name = char(eb.DisplayName);
    tr.x_data = double(eb.XData(:))';
    tr.y_data = double(eb.YData(:))';
    tr.z_data = [];

    tr.line_type = grafLineStyleToGraf(eb.LineStyle);
    tr.line_width = eb.LineWidth;
    tr.line_color = double(eb.Color(1:3));

    tr.marker_type = grafMarkerToGraf(eb.Marker);
    tr.marker_size = eb.MarkerSize;
    mfc = eb.MarkerFaceColor;
    if ischar(mfc)
        tr.marker_color = tr.line_color;
    else
        tr.marker_color = double(mfc(1:3));
    end

    tr.alpha = 1.0;
    tr.use_yaxis_R = grafColorMatches(tr.line_color, rightColor);
    tr.has_error_bars = true;

    n = numel(tr.x_data);
    tr.y_err_neg = grafOrZeros(eb.YNegativeDelta, n);
    tr.y_err_pos = grafOrZeros(eb.YPositiveDelta, n);
    tr.x_err_neg = grafOrZeros(eb.XNegativeDelta, n);
    tr.x_err_pos = grafOrZeros(eb.XPositiveDelta, n);

    tr.err_line_color = double(eb.Color(1:3));
    tr.err_cap_color = double(eb.Color(1:3));
    tr.err_line_width = eb.LineWidth;
    tr.err_cap_width = eb.LineWidth;
    tr.err_cap_size = eb.CapSize / 2;   % match Python's factor-of-2 convention
    tr.err_cap_visible = true;
end

function v = grafOrZeros(delta, n)
    if isempty(delta)
        v = zeros(1, n);
    else
        v = abs(double(delta(:)))';
    end
end

function tf = grafColorMatches(color, refColor)
    tf = ~isempty(refColor) && all(abs(color(:) - refColor(:)) < 1e-6);
end

% -----------------------------------------------------------------------------
% Surface / image axes
% -----------------------------------------------------------------------------
function ax_s = grafExtractSurfaceAxis(ax_h, ax_s)
    surfObjs = [findobj(ax_h, 'Type', 'surface'); findobj(ax_h, 'Type', 'image')];
    is3d = any(arrayfun(@(o) isa(o, 'matlab.graphics.chart.primitive.Surface') && ...
                              ~isequal(ax_h.View, [0 90]), surfObjs));
    if is3d
        ax_s.axis_type = 'AXIS_SURFACE';
    else
        ax_s.axis_type = 'AXIS_IMAGE';
    end

    ax_s.x_axis = grafExtractScale(ax_h, 'x');
    ax_s.y_axis_L = grafExtractScale(ax_h, 'y');
    ax_s.y_axis_R = grafNewScale('Valid', false);
    if is3d
        ax_s.z_axis = grafExtractScale(ax_h, 'z');
    else
        ax_s.z_axis = grafNewScale('Valid', false);
    end

    for si = 1:numel(surfObjs)
        sf = grafExtractSurface(surfObjs(si), ax_h, is3d);
        ax_s.surfaces.(sprintf('Sf%d', si - 1)) = sf;
    end
end

function sf = grafExtractSurface(surfObj, ax_h, is3d)
    sf = grafNewSurface();
    if is3d
        sf.surf_type = 'SURF_SURFACE';
    else
        sf.surf_type = 'SURF_IMAGE';
    end

    cb = findobj(ax_h.Parent, 'Type', 'colorbar');
    if ~isempty(cb)
        sf.has_colorbar = true;
        sf.colorbar_label = char(cb(1).Label.String);
        if any(strcmp(cb(1).Location, {'southoutside', 'northoutside'}))
            sf.colorbar_orientation = 'horizontal';
        end
    end

    cmapData = colormap(ax_h);
    sf.cmap = [cmapData, ones(size(cmapData, 1), 1)];

    if isprop(surfObj, 'XData')
        sf.x_grid = double(surfObj.XData);
        sf.y_grid = double(surfObj.YData);
        sf.z_grid = double(surfObj.ZData);
    elseif isprop(surfObj, 'CData')
        cdata = double(surfObj.CData);
        sf.z_grid = cdata;
        [sf.x_grid, sf.y_grid] = meshgrid(1:size(cdata, 2), 1:size(cdata, 1));
    end
    sf.uniform_grid = true;

    try
        a = get(surfObj, 'FaceAlpha');
        if isnumeric(a)
            sf.alpha = a;
        end
    catch
    end
end
