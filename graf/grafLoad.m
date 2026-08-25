function g = grafLoad(filename)
%GRAFLOAD Read a .graf (tome/HDF5) file into a MATLAB struct.
%
%   g = grafLoad(filename)
%
%   Returns [] if the file cannot be read (see tomeRead). Fills in
%   sensible defaults for any top-level/axis-level field a file happens
%   to be missing — including 'axes'/'traces'/'surfaces' dicts that were
%   omitted by grafSave under Octave (see
%   grafStripEmptyDictsForOctave.m) — so a load is always robust
%   regardless of which platform wrote the file.
    grafEnsureTomeOnPath();

    g = tomeRead(filename);
    if isempty(g)
        return
    end

    if ~isfield(g, 'supertitle');    g.supertitle = '';               end
    if ~isfield(g, 'fig_width_cm');  g.fig_width_cm = 6.4 * 2.54;      end
    if ~isfield(g, 'fig_height_cm'); g.fig_height_cm = 4.8 * 2.54;     end
    if ~isfield(g, 'style');         g.style = grafNewGraphStyle();    end
    if ~isfield(g, 'info');          g.info = grafNewMetaInfo();       end
    if ~isfield(g, 'axes') || ~isstruct(g.axes)
        g.axes = struct();
    end

    if ~isfield(g.info, 'conditions'); g.info.conditions = struct();  end
    if ~isfield(g.info, 'provenance'); g.info.provenance = struct();  end
    if ~isfield(g.info, 'history');    g.info.history = {};           end
    if isstruct(g.info.history) && isempty(fieldnames(g.info.history))
        g.info.history = {};   % an empty dict read back where a list was expected
    end

    axNames = fieldnames(g.axes);
    for i = 1:numel(axNames)
        ax = g.axes.(axNames{i});
        if ~isfield(ax, 'traces') || ~isstruct(ax.traces)
            ax.traces = struct();
        end
        if ~isfield(ax, 'surfaces') || ~isstruct(ax.surfaces)
            ax.surfaces = struct();
        end
        if ~isfield(ax, 'relative_size'); ax.relative_size = [];      end
        if ~isfield(ax, 'grid_on');       ax.grid_on = false;         end
        if ~isfield(ax, 'title');         ax.title = '';              end
        % Python's ints round-trip through tome with their exact dtype
        % (e.g. int64), which MATLAB's subplot() rejects when mixed with
        % plain doubles; graf itself has no need for that precision here.
        ax.position = double(ax.position);
        ax.span = double(ax.span);
        ax.relative_size = double(ax.relative_size);
        g.axes.(axNames{i}) = ax;
    end
end
