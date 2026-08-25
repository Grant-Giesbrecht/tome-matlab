function lowLevelWriteStringArray(filename, path, strs)
%LOWLEVELWRITESTRINGARRAY Write a non-empty 1xN (or Nx1) cell array of
%   char row vectors as a true rank-1 vlen UTF-8 string dataset.
%   Used on MATLAB, where h5create/h5write only gained 'Datatype',
%   'string' support around R2020b; this low-level path works on any
%   release with the H5* low-level HDF5 interface (~R2011a+).
    n = numel(strs);
    fid = lowLevelOpenForWrite(filename);
    tid = H5T.copy('H5T_C_S1');
    H5T.set_size(tid, 'H5T_VARIABLE');
    H5T.set_cset(tid, 'H5T_CSET_UTF8');
    sid = H5S.create_simple(1, n, n);
    lcpl = H5P.create('H5P_LINK_CREATE');
    H5P.set_create_intermediate_group(lcpl, 1);
    did = H5D.create(fid, path, tid, sid, lcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');
    H5D.write(did, tid, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', strs);
    H5D.close(did);
    H5S.close(sid);
    H5T.close(tid);
    H5P.close(lcpl);
    H5F.close(fid);
end
