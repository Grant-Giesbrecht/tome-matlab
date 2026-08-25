function writeComplexDataset(filename, path, value)
%WRITECOMPLEXDATASET Write a scalar or non-empty array complex VALUE as
%   an HDF5 compound {r,i} dataset, matching h5py's native complex128
%   mapping. VALUE is the ORIGINAL (not yet axis-permuted) MATLAB value;
%   this function applies whichever axis convention its own write path
%   needs (Octave's high-level h5create/h5write, or MATLAB's low-level
%   H5D.write, empirically do NOT share the same convention).
    if isscalar(value)
        if isOctaveRuntime()
            h5create(filename, path, 1, 'Datatype', 'double complex');
            h5write(filename, path, value);
        else
            lowLevelWriteComplex(filename, path, value, []);
        end
        return
    end

    isVec = isvector(value);
    if isOctaveRuntime()
        % High-level h5create/h5write: dims reversed, data axis-permuted
        % (same convention as writeArray's real-number path).
        if isVec
            dims = numel(value);
            data = value(:);
        else
            dims = fliplr(size(value));
            data = permute(value, ndims(value):-1:1);
        end
        h5create(filename, path, dims, 'Datatype', 'double complex');
        h5write(filename, path, data);
    else
        % Low-level H5D.write: dims NOT reversed, data still axis-permuted.
        if isVec
            dims = numel(value);
            data = value(:);
        else
            dims = size(value);
            data = permute(value, ndims(value):-1:1);
        end
        lowLevelWriteComplex(filename, path, data, dims);
    end
end
