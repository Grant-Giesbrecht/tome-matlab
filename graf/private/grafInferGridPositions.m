function positions = grafInferGridPositions(axHandles, tol)
%GRAFINFERGRIDPOSITIONS Infer a GridSpec-style (row, col) position + span
%   for each axes handle from its on-figure bounding box (normalized
%   Position). Unlike a naive shared-edge clustering (which breaks on
%   MATLAB subplot's inter-axes gaps — two "adjacent" cells' facing
%   edges don't actually touch), this clusters each axis's START edge
%   only (left edge for columns, top edge for rows) into grid lines,
%   then determines each axis's span by counting how many of those grid
%   lines fall strictly before its stop edge. Column/row logic is
%   identical modulo the fact that grid rows run top-to-bottom while
%   normalized figure Y increases bottom-to-top, handled by negating Y.
%
%   Returns a containers.Map from axes handle (as double(handle)) to a
%   1x2 cell {[row_start col_start], [row_span col_span]} (0-based,
%   matching the GrAF position/span convention).
    if nargin < 2
        tol = 0.02;
    end
    positions = containers.Map('KeyType', 'double', 'ValueType', 'any');
    n = numel(axHandles);
    if n == 0
        return
    end

    x0 = zeros(n, 1); x1 = zeros(n, 1);
    y0 = zeros(n, 1); y1 = zeros(n, 1);
    for i = 1:n
        h = axHandles(i);
        origUnits = h.Units;
        h.Units = 'normalized';
        pos = h.Position;   % [left bottom width height]
        h.Units = origUnits;
        x0(i) = pos(1);
        x1(i) = pos(1) + pos(3);
        y0(i) = pos(2);
        y1(i) = pos(2) + pos(4);
    end

    colAssign = inferAxisSpans(x0, x1, tol);
    rowAssign = inferAxisSpans(-y1, -y0, tol);   % top-to-bottom via negation

    for i = 1:n
        key = double(axHandles(i));
        rowStart = rowAssign(i, 1); rowSpan = rowAssign(i, 2) - rowAssign(i, 1);
        colStart = colAssign(i, 1); colSpan = colAssign(i, 2) - colAssign(i, 1);
        positions(key) = {[rowStart, colStart], [rowSpan, colSpan]};
    end
end

function assign = inferAxisSpans(starts, stops, tol)
    edges = clusterEdges(starts, tol);   % sorted ascending, deduped grid lines
    n = numel(starts);
    assign = zeros(n, 2);
    for i = 1:n
        [~, idx] = min(abs(edges - starts(i)));
        colStart = idx - 1;   % 0-based
        colStop = sum(edges < stops(i) - tol);
        if colStop <= colStart
            colStop = colStart + 1;
        end
        assign(i, :) = [colStart, colStop];
    end
end

function edges = clusterEdges(values, tol)
    values = sort(values(:));
    clusters = {values(1)};
    for i = 2:numel(values)
        v = values(i);
        if v - clusters{end}(end) <= tol
            clusters{end}(end + 1) = v;
        else
            clusters{end + 1} = v; %#ok<AGROW>
        end
    end
    edges = cellfun(@mean, clusters);
end
