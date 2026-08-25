function writeArray(filename, path, value)
%WRITEARRAY Write a non-empty numeric/logical array as a tome 'ndarray'.
%
%   HDF5 stores datasets in row-major order; MATLAB/Octave store arrays
%   column-major. A plain vector (row or column) is written as a true
%   rank-1 dataset, matching a NumPy 1-D array. A matrix or N-D array is
%   written with its dimensions reversed and its data fully axis-permuted
%   (a self-inverse transform), so that a reader in NumPy/h5py sees the
%   exact same shape and element-for-element values as MATLAB's size(A).
    if isempty(value)
        writeEmptyArray(filename, path);
        return
    end

    if ~isreal(value)
        writeComplexDataset(filename, path, value);
        writeAttr(filename, path, '__pytype__', 'ndarray');
        writeAttr(filename, path, 'dtype', 'complex128');
        return
    end

    cls = class(value);
    isVec = isvector(value);
    if isVec
        dims = numel(value);
        data = value(:);
    else
        dims = fliplr(size(value));
        data = permute(value, ndims(value):-1:1);
    end

    if strcmp(cls, 'logical')
        data = int8(data);
    end
    octType = h5TypeStrings(cls);

    % Real numeric/logical(-as-int8) arrays are natively supported by
    % h5create/h5write on both MATLAB and Octave, so no low-level path
    % is needed here (unlike scalars and complex data).
    h5create(filename, path, dims, 'Datatype', octType);
    h5write(filename, path, data);

    writeAttr(filename, path, '__pytype__', 'ndarray');
    writeAttr(filename, path, 'dtype', dtypeNameFromClass(cls));
end
