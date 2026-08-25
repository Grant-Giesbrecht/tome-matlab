function v = reconstructArrayShape(raw)
%RECONSTRUCTARRAYSHAPE Undo the tome ndarray axis convention on data
%   already read back by h5read. A true 1-D HDF5 dataset always comes
%   back from h5read as a MATLAB vector (row or column depending on
%   platform); normalize that to a row. Anything of rank >= 2 is restored
%   via the same full-axis-reversal permute used on write (a self-inverse
%   transform), giving back the original MATLAB shape.
    if isvector(raw)
        v = reshape(raw, 1, []);
    else
        v = permute(raw, ndims(raw):-1:1);
    end
end
