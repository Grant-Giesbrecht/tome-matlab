function [octType, lowLevelTypeId] = h5TypeStrings(matlabClass)
%H5TYPESTRINGS Map a MATLAB/Octave numeric class to the Datatype string
%   used by Octave's high-level h5create, and the predefined HDF5 type
%   id used by MATLAB's low-level H5T interface. Logical is represented
%   on disk as a signed 8-bit integer (0/1); callers must cast the data.
    switch matlabClass
        case 'double'
            octType = 'double';       lowLevelTypeId = 'H5T_IEEE_F64LE';
        case 'single'
            octType = 'single';       lowLevelTypeId = 'H5T_IEEE_F32LE';
        case 'int8'
            octType = 'int8';         lowLevelTypeId = 'H5T_STD_I8LE';
        case 'int16'
            octType = 'int16';        lowLevelTypeId = 'H5T_STD_I16LE';
        case 'int32'
            octType = 'int32';        lowLevelTypeId = 'H5T_STD_I32LE';
        case 'int64'
            octType = 'int64';        lowLevelTypeId = 'H5T_STD_I64LE';
        case 'uint8'
            octType = 'uint8';        lowLevelTypeId = 'H5T_STD_U8LE';
        case 'uint16'
            octType = 'uint16';       lowLevelTypeId = 'H5T_STD_U16LE';
        case 'uint32'
            octType = 'uint32';       lowLevelTypeId = 'H5T_STD_U32LE';
        case 'uint64'
            octType = 'uint64';       lowLevelTypeId = 'H5T_STD_U64LE';
        case 'logical'
            octType = 'int8';         lowLevelTypeId = 'H5T_STD_I8LE';
        otherwise
            error('tome:h5TypeStrings:unsupported', ...
                'Unsupported numeric class ''%s''.', matlabClass);
    end
end
