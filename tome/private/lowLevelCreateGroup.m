function lowLevelCreateGroup(filename, path)
%LOWLEVELCREATEGROUP Explicitly create an (possibly empty) HDF5 group.
%   Used only for MATLAB (Octave has no low-level H5G access); needed so
%   that an empty struct/containers.Map still produces a real group node
%   rather than being silently dropped.
    fid = lowLevelOpenForWrite(filename);
    lcpl = H5P.create('H5P_LINK_CREATE');
    H5P.set_create_intermediate_group(lcpl, 1);
    gid = H5G.create(fid, path, lcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');
    H5G.close(gid);
    H5P.close(lcpl);
    H5F.close(fid);
end
