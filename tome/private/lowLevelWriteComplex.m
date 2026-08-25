function lowLevelWriteComplex(filename, path, value, dims)
%LOWLEVELWRITECOMPLEX Write a complex dataset as the HDF5 compound type
%   {double r; double i;} that h5py emits for complex128, so it reads
%   back natively as a Python/NumPy complex value.
%
%   DIMS = [] (or omitted) writes a true scalar (0-D) dataset from a
%   scalar VALUE. Otherwise DIMS is the HDF5 dataspace extent (already in
%   tome's on-disk axis order) and VALUE must have matching element
%   count, in the same linear order as DIMS expects.
    if nargin < 4
        dims = [];
    end

    fid = H5F.open(filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
    tid_d = H5T.copy('H5T_IEEE_F64LE');
    sz = H5T.get_size(tid_d);
    tid_c = H5T.create('H5T_COMPOUND', 2 * sz);
    H5T.insert(tid_c, 'r', 0, tid_d);
    H5T.insert(tid_c, 'i', sz, tid_d);

    if isempty(dims)
        sid = H5S.create('H5S_SCALAR');
    else
        sid = H5S.create_simple(numel(dims), dims, dims);
    end

    lcpl = H5P.create('H5P_LINK_CREATE');
    H5P.set_create_intermediate_group(lcpl, 1);
    did = H5D.create(fid, path, tid_c, sid, lcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');
    data = struct('r', real(value), 'i', imag(value));
    H5D.write(did, tid_c, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', data);

    H5D.close(did);
    H5S.close(sid);
    H5T.close(tid_c);
    H5T.close(tid_d);
    H5P.close(lcpl);
    H5F.close(fid);
end
