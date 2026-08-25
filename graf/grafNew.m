function g = grafNew(varargin)
%GRAFNEW Default Graf struct, matching graf.base.Graf()'s defaults.
%   g = grafNew()
%   g = grafNew('Description', '...', 'Conditions', struct(...))
%
%   g.axes starts as an empty struct (an empty dict, matching the Python
%   default {}); note that a Graf with zero axes cannot be saved under
%   Octave (see README) since hdf5oct has no low-level HDF5
%   group-creation API for the resulting empty dict. Add at least one
%   axis (g.axes.Ax0 = grafNewAxis(); ...) before saving there.
    p = inputParser();
    p.addParameter('Description', '');
    p.addParameter('Conditions', struct());
    p.parse(varargin{:});

    g = struct();
    g.style = grafNewGraphStyle();
    g.info = grafNewMetaInfo('Description', p.Results.Description, ...
                              'Conditions', p.Results.Conditions);
    g.supertitle = '';
    g.fig_width_cm = 6.4 * 2.54;
    g.fig_height_cm = 4.8 * 2.54;
    g.axes = struct();
end
