function ok = writegraf(g, filename, varargin)
%WRITEGRAF Write a GrAF struct to a .graf (tome/HDF5) file.
%
%   ok = writegraf(g, filename)
%   ok = writegraf(g, filename, 'SourceApp', 'my_app 1.0', 'Action', 'edited')
%
%   g must be a struct produced by grafNew/fig2graf (or readgraf).
%   Stamps g.info.provenance (once) and appends a g.info.history entry
%   on every call, mirroring Python's Graf.write_graf choke point.
%   Overwrites filename if it already exists. Returns true on success,
%   false on failure (see tomeWrite).
%
%   See also savegraf, which goes straight from a MATLAB figure to a
%   .graf file in one step (mirrors Python's save_graf).
    grafEnsureTomeOnPath();

    p = inputParser();
    p.addParameter('SourceApp', '');
    p.addParameter('Action', '');
    p.parse(varargin{:});

    g = grafStampProvenance(g, 'SourceApp', p.Results.SourceApp, ...
                             'Action', p.Results.Action);
    g = grafStripEmptyDictsForOctave(g);
    ok = tomeWrite(g, filename);
end
