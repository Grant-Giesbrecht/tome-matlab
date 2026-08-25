function name = basenamePath(fullPath)
%BASENAMEPATH Last path segment of an HDF5 link path, e.g.
%   '/settings/gain' -> 'gain'.
    parts = strsplit(fullPath, '/');
    name = parts{end};
end
