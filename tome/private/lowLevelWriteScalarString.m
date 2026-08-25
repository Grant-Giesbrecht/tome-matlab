function lowLevelWriteScalarString(filename, path, strValue)
%LOWLEVELWRITESCALARSTRING Write a true scalar (0-D) variable-length
%   UTF-8 string dataset, matching h5py's convention for a Python str.
    fid = lowLevelOpenForWrite(filename);
    tid = H5T.copy('H5T_C_S1');
    H5T.set_size(tid, 'H5T_VARIABLE');
    H5T.set_cset(tid, 'H5T_CSET_UTF8');
    sid = H5S.create('H5S_SCALAR');
    lcpl = H5P.create('H5P_LINK_CREATE');
    H5P.set_create_intermediate_group(lcpl, 1);
    did = H5D.create(fid, path, tid, sid, lcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');
    % Wrapped in a cell so H5D.write treats it as one vlen-string element
    % matching the scalar dataspace, rather than one element per char
    % (the bare-char form happens to work on newer MATLAB but not on
    % R2019b, where it errors with an element-count mismatch).
    H5D.write(did, tid, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', {char(strValue)});
    H5D.close(did);
    H5S.close(sid);
    H5T.close(tid);
    H5P.close(lcpl);
    H5F.close(fid);
end
