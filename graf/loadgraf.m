function fig = loadgraf(filename, varargin)
%LOADGRAF Read a .graf (tome/HDF5) file directly into a MATLAB figure.
%
%   fig = loadgraf(filename)
%   fig = loadgraf(filename, 'Scale', 1.5)
%   fig = loadgraf(filename, 'Title', 'My Window')
%
%   One-step convenience mirroring Python's load_graf: readgraf(filename)
%   followed by graf2fig(g). Options are forwarded to graf2fig.
%   MATLAB-only — see fig2graf.m for why. Returns the new figure handle,
%   or [] if the file could not be read (see readgraf).
%
%   See also readgraf (file -> struct only), graf2fig (struct -> fig
%   only), savegraf (the figure -> file counterpart).
    g = readgraf(filename);
    if isempty(g)
        fig = [];
        return
    end
    fig = graf2fig(g, varargin{:});
end
