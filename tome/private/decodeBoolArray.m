function v = decodeBoolArray(raw)
%DECODEBOOLARRAY Normalize a raw bool-dtype ndarray/list dataset.
%   h5py writes NumPy bool arrays as an HDF5 enum {FALSE=0, TRUE=1};
%   MATLAB's h5read hands that back as a cell array of 'TRUE'/'FALSE'
%   strings (Octave/hdf5oct already decodes it to a native logical
%   array, so this is a no-op there).
    if iscell(raw)
        v = reshape(strcmpi(raw, 'TRUE'), size(raw));
    else
        v = logical(raw);
    end
end
