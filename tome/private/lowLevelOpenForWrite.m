function fid = lowLevelOpenForWrite(filename)
%LOWLEVELOPENFORWRITE Open an existing HDF5 file for low-level writing.
%   The file must already exist; tome.write creates it up front via
%   H5F.create so that both high-level (h5create/h5write) and low-level
%   (H5D.create/H5D.write) calls can target the same open-on-demand file.
    fid = H5F.open(filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
end
