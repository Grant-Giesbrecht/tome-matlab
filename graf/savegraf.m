function ok = savegraf(fig, filename, varargin)
%SAVEGRAF Write a MATLAB figure directly to a .graf (tome/HDF5) file.
%
%   ok = savegraf(fig, filename)
%   ok = savegraf(fig, filename, 'SourceApp', 'my_app 1.0', 'Action', 'edited')
%   ok = savegraf(filename)              % uses gcf
%
%   One-step convenience mirroring Python's save_graf: fig2graf(fig)
%   followed by writegraf(g, filename). fig may be a figure handle, or
%   the path to a .fig file (opened via openfig). MATLAB-only — see
%   fig2graf.m for why. Returns true on success, false on failure.
%
%   See also writegraf (struct -> file only), fig2graf (fig -> struct
%   only), loadgraf (the file -> figure counterpart).
    if nargin < 2 && (ischar(fig) || (isstring(fig) && isscalar(fig)))
        filename = fig;
        fig = gcf;
    end

    if ~isgraphics(fig, 'figure')
        fig = openfig(char(fig));
    end
    if ~isgraphics(fig, 'figure')
        error('savegraf:invalidFig', 'fig must be a figure handle or a path to a .fig file');
    end

    g = fig2graf(fig);
    ok = writegraf(g, filename, varargin{:});
end
