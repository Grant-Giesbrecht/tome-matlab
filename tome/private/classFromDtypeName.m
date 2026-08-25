function cls = classFromDtypeName(name)
%CLASSFROMDTYPENAME Map a NumPy-style dtype name back to a MATLAB/Octave
%   numeric class, for restoring the exact element width on read.
    switch name
        case {'float64','float_','double'}
            cls = 'double';
        case {'float32','single'}
            cls = 'single';
        case {'int8','int16','int32','int64', ...
              'uint8','uint16','uint32','uint64'}
            cls = name;
        case 'bool'
            cls = 'logical';
        otherwise
            cls = '';  % unknown: leave data as-is
    end
end
