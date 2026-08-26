function g = grafStripEmptyDictsForOctave(g)
%GRAFSTRIPEMPTYDICTSFOROCTAVE Work around Octave's inability to write an
%   empty HDF5 group (tome's dict tag): omit an empty 'traces'/'surfaces'
%   (per axis) or 'axes' (root) field entirely rather than erroring.
%
%   This is a real, common case for GrAF specifically (any single-purpose
%   axis has an empty surfaces OR traces dict), not an edge case — so
%   unlike tome's generic library behaviour (which errors, the right
%   conservative default for a format library), writegraf silently adapts
%   here under Octave and warns once.
%
%   Consequence: an Octave-written .graf file with an axis that has an
%   empty traces or surfaces dict is NOT fully readable by Python's raw
%   Graf.read_graf()/unpack() for that axis, because Packable.unpack()
%   does not tolerate a missing dict_manifest key. readgraf (this
%   package) tolerates it fine on either platform by filling the field
%   back in as an empty struct on read.
    if ~isOctaveRuntimeGraf()
        return
    end

    warned = false;

    if isfield(g, 'info') && isstruct(g.info) && isfield(g.info, 'conditions') ...
            && isstruct(g.info.conditions) && isempty(fieldnames(g.info.conditions))
        g.info = rmfield(g.info, 'conditions');
        warned = true;
    end

    if isfield(g, 'axes') && isstruct(g.axes)
        axNames = fieldnames(g.axes);
        for i = 1:numel(axNames)
            axName = axNames{i};
            ax = g.axes.(axName);
            for fn = {'traces', 'surfaces'}
                fname = fn{1};
                if isfield(ax, fname) && isstruct(ax.(fname)) && isempty(fieldnames(ax.(fname)))
                    ax = rmfield(ax, fname);
                    warned = true;
                end
            end
            g.axes.(axName) = ax;
        end
        if isempty(axNames)
            g = rmfield(g, 'axes');
            warned = true;
        end
    end

    if warned
        warning('graf:save:octaveEmptyDictOmitted', ...
            ['Omitted one or more empty traces/surfaces/axes dicts because ' ...
             'Octave cannot write an empty HDF5 group. readgraf restores ' ...
             'them as empty on read, but a raw Python Graf.read_graf() call ' ...
             'will fail on the affected axis/axes. See grafStripEmptyDictsForOctave.m.']);
    end
end

function tf = isOctaveRuntimeGraf()
    tf = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
end
