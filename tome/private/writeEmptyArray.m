function writeEmptyArray(filename, path)
%WRITEEMPTYARRAY Write a zero-length float64 dataset, matching the tome
%   convention for an empty Python list ("carries no information about
%   the intended element type").
    if isOctaveRuntime()
        h5create(filename, path, [1 Inf], 'Datatype', 'double', 'ChunkSize', [1 1]);
    else
        fid = lowLevelOpenForWrite(filename);
        tid = H5T.copy('H5T_IEEE_F64LE');
        sid = H5S.create_simple(1, 0, 0);
        lcpl = H5P.create('H5P_LINK_CREATE');
        H5P.set_create_intermediate_group(lcpl, 1);
        did = H5D.create(fid, path, tid, sid, lcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');
        H5D.close(did);
        H5S.close(sid);
        H5T.close(tid);
        H5P.close(lcpl);
        H5F.close(fid);
    end
    writeAttr(filename, path, '__pytype__', 'list');
    writeAttr(filename, path, 'dtype', 'float64');
end
