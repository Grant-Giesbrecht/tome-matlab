function childPath = resolveChildPath(groupPath, name)
%RESOLVECHILDPATH Normalize an h5info child Name into a full HDF5 path.
%   Real MATLAB's h5info reports Datasets(i).Name as a bare leaf name but
%   Groups(i).Name as a full absolute path; Octave's hdf5oct reports both
%   as full absolute paths. Handle either convention.
    if ~isempty(name) && name(1) == '/'
        childPath = name;
    else
        childPath = joinPath(groupPath, name);
    end
end
