function v = combineComplexRaw(raw)
%COMBINECOMPLEXRAW MATLAB's h5read returns a compound {r,i} dataset as a
%   struct with fields r/i (Octave's hdf5oct recombines it into a native
%   complex array already). Normalize both to a native complex array.
    if isstruct(raw)
        v = complex(raw.r, raw.i);
    else
        v = raw;
    end
end
