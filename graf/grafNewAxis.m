function ax = grafNewAxis()
%GRAFNEWAXIS Default Axis struct, matching graf.base.Axis()'s defaults.
%   traces/surfaces start as empty structs (an empty dict, matching the
%   Python default {}); note that an Axis with zero traces AND zero
%   surfaces cannot be saved under Octave (see README) since hdf5oct has
%   no low-level HDF5 group-creation API for the resulting empty dict.
    ax = struct();
    ax.axis_type = 'AXIS_LINE2D';
    ax.position = [0 0];
    ax.span = [1 1];
    ax.relative_size = [];
    ax.x_axis = grafNewScale();
    ax.y_axis_L = grafNewScale();
    ax.y_axis_R = grafNewScale('Valid', false);
    ax.z_axis = grafNewScale('Valid', false);
    ax.grid_on = false;
    ax.traces = struct();
    ax.surfaces = struct();
    ax.title = '';
end
