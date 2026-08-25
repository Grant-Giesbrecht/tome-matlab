function fig = grafToFig(g, varargin)
%GRAFTOFIG Reconstruct a MATLAB figure from a GrAF struct.
%
%   fig = grafToFig(g)
%   fig = grafToFig(g, 'Scale', 1.5)
%   fig = grafToFig(g, 'Title', 'My Window')
%
%   Options (name-value pairs):
%     'Scale'  - multiplicative size scale factor (default 1.0)
%     'Title'  - figure window title string
%
%   Returns the MATLAB figure handle.
%
%   MATLAB-only — see grafFromFig.m for why.
    p = inputParser();
    p.addParameter('Scale', 1.0);
    p.addParameter('Title', '');
    p.parse(varargin{:});
    scaleFactor = p.Results.Scale;
    winTitle = p.Results.Title;

    cm_per_inch = 2.54;
    w_in = g.fig_width_cm  / cm_per_inch * scaleFactor;
    h_in = g.fig_height_cm / cm_per_inch * scaleFactor;

    if isempty(winTitle)
        fig = figure('Units', 'inches', 'Position', [1 1 w_in h_in]);
    else
        fig = figure('Name', winTitle, 'Units', 'inches', 'Position', [1 1 w_in h_in]);
    end

    if ~isempty(g.supertitle)
        sgtitle(fig, g.supertitle);
    end

    axNames = fieldnames(g.axes);
    if isempty(axNames)
        return
    end

    % Grid extent: the smallest uniform grid that fits every axis's
    % [position, position+span) block, matching Graf.to_fig's GridSpec sizing.
    maxRow = 1; maxCol = 1;
    for ai = 1:numel(axNames)
        ax_s = g.axes.(axNames{ai});
        maxRow = max(maxRow, ax_s.position(1) + ax_s.span(1));
        maxCol = max(maxCol, ax_s.position(2) + ax_s.span(2));
    end

    for ai = 1:numel(axNames)
        ax_s = g.axes.(axNames{ai});

        row = ax_s.position(1) + 1;
        col = ax_s.position(2) + 1;
        rspan = ax_s.span(1);
        cspan = ax_s.span(2);

        idxs = [];
        for r = row:(row + rspan - 1)
            for c = col:(col + cspan - 1)
                idxs(end + 1) = (r - 1) * maxCol + c; %#ok<AGROW>
            end
        end

        if ax_s.z_axis.is_valid
            ax_h = subplot(maxRow, maxCol, idxs, 'Parent', fig);
            view(ax_h, 3);
        else
            ax_h = subplot(maxRow, maxCol, idxs, 'Parent', fig);
        end
        hold(ax_h, 'on');

        if strcmp(ax_s.axis_type, 'AXIS_SURFACE') || strcmp(ax_s.axis_type, 'AXIS_IMAGE')
            grafRenderSurfaceAxis(fig, ax_h, ax_s);
        else
            grafRenderLineAxis(ax_h, ax_s);
        end

        grafApplyAxisLabels(ax_h, ax_s);
        if ax_s.grid_on
            grid(ax_h, 'on');
        end
    end
end

% -----------------------------------------------------------------------------
% Line / scatter / error-bar axes
% -----------------------------------------------------------------------------
function grafRenderLineAxis(ax_h, ax_s)
    trNames = fieldnames(ax_s.traces);

    hasRight = ax_s.y_axis_R.is_valid;
    if hasRight
        yyaxis(ax_h, 'left');
    end

    for ti = 1:numel(trNames)
        tr = ax_s.traces.(trNames{ti});
        if hasRight
            if tr.use_yaxis_R
                yyaxis(ax_h, 'right');
            else
                yyaxis(ax_h, 'left');
            end
        end
        if tr.has_error_bars
            grafDrawErrorbar(ax_h, tr);
        elseif strcmp(tr.trace_type, 'TRACE_LINE3D')
            grafDrawLine3D(ax_h, tr);
        else
            grafDrawLine2D(ax_h, tr);
        end
    end

    if hasRight
        yyaxis(ax_h, 'right');
        if ~isempty(ax_s.y_axis_R.label)
            ylabel(ax_h, ax_s.y_axis_R.label);
        end
        grafApplyScale(ax_h, 'y', ax_s.y_axis_R);
        yyaxis(ax_h, 'left');
    end

    if ax_s.z_axis.is_valid
        if ~isempty(ax_s.z_axis.label)
            zlabel(ax_h, ax_s.z_axis.label);
        end
        grafApplyScale(ax_h, 'z', ax_s.z_axis);
    end
end

function grafDrawLine2D(ax_h, tr)
    h = plot(ax_h, tr.x_data, tr.y_data, ...
        'LineStyle',       grafLineStyleFromGraf(tr.line_type), ...
        'Marker',          grafMarkerFromGraf(tr.marker_type), ...
        'LineWidth',       tr.line_width, ...
        'MarkerSize',      tr.marker_size, ...
        'Color',           double(tr.line_color(:)'), ...
        'MarkerFaceColor', double(tr.marker_color(:)'), ...
        'DisplayName',     tr.display_name);
    if tr.alpha < 1.0
        h.Color(4) = tr.alpha;
    end
    grafSetLegendVisibility(h, tr.include_in_legend);
end

function grafDrawLine3D(ax_h, tr)
    h = plot3(ax_h, tr.x_data, tr.y_data, tr.z_data, ...
        'LineStyle',   grafLineStyleFromGraf(tr.line_type), ...
        'Marker',      grafMarkerFromGraf(tr.marker_type), ...
        'LineWidth',   tr.line_width, ...
        'MarkerSize',  tr.marker_size, ...
        'Color',       double(tr.line_color(:)'), ...
        'DisplayName', tr.display_name);
    grafSetLegendVisibility(h, tr.include_in_legend);
end

function grafDrawErrorbar(ax_h, tr)
    yErrNeg = tr.y_err_neg(:);
    yErrPos = tr.y_err_pos(:);
    xErrNeg = tr.x_err_neg(:);
    xErrPos = tr.x_err_pos(:);

    hasYErr = any(yErrNeg > 0) || any(yErrPos > 0);
    hasXErr = any(xErrNeg > 0) || any(xErrPos > 0);

    args = {'LineStyle', grafLineStyleFromGraf(tr.line_type), ...
            'Marker', grafMarkerFromGraf(tr.marker_type), ...
            'LineWidth', tr.line_width, 'MarkerSize', tr.marker_size, ...
            'Color', double(tr.line_color(:)'), ...
            'MarkerFaceColor', double(tr.marker_color(:)'), ...
            'DisplayName', tr.display_name, ...
            'CapSize', tr.err_cap_size * 2};

    x = tr.x_data(:); y = tr.y_data(:);
    if hasYErr && hasXErr
        h = errorbar(ax_h, x, y, yErrNeg, yErrPos, xErrNeg, xErrPos, args{:});
    elseif hasYErr
        h = errorbar(ax_h, x, y, yErrNeg, yErrPos, args{:});
    elseif hasXErr
        h = errorbar(ax_h, x, y, [], [], xErrNeg, xErrPos, args{:});
    else
        h = errorbar(ax_h, x, y, zeros(size(y)), zeros(size(y)), args{:});
    end
    grafSetLegendVisibility(h, tr.include_in_legend);
end

function grafSetLegendVisibility(h, includeInLegend)
    if ~includeInLegend
        try
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
        catch
        end
    end
end

function grafApplyScale(ax_h, whichAxis, sc)
    useLog = strcmpi(sc.scale_type, 'log');
    switch whichAxis
        case 'x'
            if useLog
                set(ax_h, 'XScale', 'log');
            else
                set(ax_h, 'XScale', 'linear');
                if ~isempty(sc.tick_list)
                    set(ax_h, 'XTick', sc.tick_list);
                end
                if ~isempty(sc.tick_label_list)
                    set(ax_h, 'XTickLabel', sc.tick_label_list);
                end
            end
            if sc.is_valid && sc.val_min < sc.val_max
                xlim(ax_h, [sc.val_min, sc.val_max]);
            end
        case 'y'
            if useLog
                set(ax_h, 'YScale', 'log');
            else
                set(ax_h, 'YScale', 'linear');
                if ~isempty(sc.tick_list)
                    set(ax_h, 'YTick', sc.tick_list);
                end
                if ~isempty(sc.tick_label_list)
                    set(ax_h, 'YTickLabel', sc.tick_label_list);
                end
            end
            if sc.is_valid && sc.val_min < sc.val_max
                ylim(ax_h, [sc.val_min, sc.val_max]);
            end
        case 'z'
            if ~isempty(sc.tick_list)
                set(ax_h, 'ZTick', sc.tick_list);
            end
            if ~isempty(sc.tick_label_list)
                set(ax_h, 'ZTickLabel', sc.tick_label_list);
            end
            if sc.is_valid && sc.val_min < sc.val_max
                zlim(ax_h, [sc.val_min, sc.val_max]);
            end
    end
end

% -----------------------------------------------------------------------------
% Surface / image axes
% -----------------------------------------------------------------------------
function grafRenderSurfaceAxis(fig, ax_h, ax_s)
    sfNames = fieldnames(ax_s.surfaces);
    if isempty(sfNames)
        return
    end
    sf = ax_s.surfaces.(sfNames{1});
    X = double(sf.x_grid);
    Y = double(sf.y_grid);
    Z = double(sf.z_grid);

    if strcmp(sf.surf_type, 'SURF_SURFACE')
        h = surf(ax_h, X, Y, Z);
        shading(ax_h, 'interp');
        view(ax_h, 3);
    else
        [nrx, ncx] = size(X);
        [nrz, ncz] = size(Z);
        if nrx == nrz + 1 && ncx == ncz + 1
            % Corner-based grid (as matplotlib's pcolormesh stores it via
            % QuadMesh._coordinates): X/Y are (M+1)x(N+1), Z is MxN. pcolor
            % needs all three the same size; pad Z with a repeated border
            % (the extra row/col is invisible under flat shading).
            Z = Z([1:end, end], [1:end, end]);
            h = pcolor(ax_h, X, Y, Z);
            shading(ax_h, 'flat');
        else
            h = pcolor(ax_h, X, Y, Z);
            shading(ax_h, 'interp');
        end
    end

    if ~isempty(sf.cmap) && size(sf.cmap, 2) >= 3
        colormap(ax_h, sf.cmap(:, 1:3));
    end
    if isfinite(sf.alpha) && sf.alpha < 1.0
        try
            h.FaceAlpha = sf.alpha;
        catch
        end
    end

    if sf.has_colorbar
        cb = colorbar(ax_h);
        if ~isempty(sf.colorbar_label)
            cb.Label.String = sf.colorbar_label;
        end
        if strcmpi(sf.colorbar_orientation, 'horizontal')
            cb.Location = 'southoutside';
        end
        if ~isnan(sf.colorbar_vmin) && ~isnan(sf.colorbar_vmax)
            caxis(ax_h, [sf.colorbar_vmin, sf.colorbar_vmax]); %#ok<CAXIS> (caxis, not clim, for pre-R2022a compat)
        end
    end
end

% -----------------------------------------------------------------------------
% Common axis formatting
% -----------------------------------------------------------------------------
function grafApplyAxisLabels(ax_h, ax_s)
    if ~isempty(ax_s.title)
        title(ax_h, ax_s.title);
    end
    if ~isempty(ax_s.x_axis.label)
        xlabel(ax_h, ax_s.x_axis.label);
    end
    grafApplyScale(ax_h, 'x', ax_s.x_axis);
    if ~isempty(ax_s.y_axis_L.label)
        ylabel(ax_h, ax_s.y_axis_L.label);
    end
    grafApplyScale(ax_h, 'y', ax_s.y_axis_L);
end
