function lowLevelWriteAttrString(filename, path, name, value)
%LOWLEVELWRITEATTRSTRING Write a vlen UTF-8 string attribute on the
%   group or dataset at PATH. Used on MATLAB instead of h5writeatt:
%   older MATLAB releases (confirmed on R2019b) write a fixed-length
%   ASCII attribute by default, which h5py reads back as raw bytes
%   rather than str, silently breaking every '__pytype__'/'dtype'
%   comparison downstream. H5O.open works uniformly on either a group
%   or a dataset, so this needs no group/dataset branch.
    fid = lowLevelOpenForWrite(filename);
    oid = H5O.open(fid, path, 'H5P_DEFAULT');
    tid = H5T.copy('H5T_C_S1');
    H5T.set_size(tid, 'H5T_VARIABLE');
    H5T.set_cset(tid, 'H5T_CSET_UTF8');
    sid = H5S.create('H5S_SCALAR');
    aid = H5A.create(oid, name, tid, sid, 'H5P_DEFAULT');
    H5A.write(aid, tid, {char(value)});
    H5A.close(aid);
    H5S.close(sid);
    H5T.close(tid);
    H5O.close(oid);
    H5F.close(fid);
end
