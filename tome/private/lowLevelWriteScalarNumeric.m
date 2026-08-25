function lowLevelWriteScalarNumeric(filename, path, value, lowLevelTypeId)
%LOWLEVELWRITESCALARNUMERIC Write a true scalar (0-D) numeric dataset.
    fid = lowLevelOpenForWrite(filename);
    tid = H5T.copy(lowLevelTypeId);
    sid = H5S.create('H5S_SCALAR');
    lcpl = H5P.create('H5P_LINK_CREATE');
    H5P.set_create_intermediate_group(lcpl, 1);
    did = H5D.create(fid, path, tid, sid, lcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');
    H5D.write(did, tid, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', value);
    H5D.close(did);
    H5S.close(sid);
    H5T.close(tid);
    H5P.close(lcpl);
    H5F.close(fid);
end
