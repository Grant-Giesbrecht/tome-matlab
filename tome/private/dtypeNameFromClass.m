function name = dtypeNameFromClass(cls)
%DTYPENAMEFROMCLASS Map a MATLAB/Octave numeric class name to the
%   NumPy-style dtype name used in tome '__pytype__'/'dtype' attributes.
    switch cls
        case 'double'
            name = 'float64';
        case 'single'
            name = 'float32';
        case {'int8','int16','int32','int64', ...
              'uint8','uint16','uint32','uint64'}
            name = cls;
        case 'logical'
            name = 'bool';
        otherwise
            error('tome:dtypeNameFromClass:unsupported', ...
                'Unsupported numeric class ''%s''.', cls);
    end
end
