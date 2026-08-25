function writeScalarBool(filename, path, value)
%WRITESCALARBOOL Write a logical scalar as a tome 'bool' (0/1 int8).
    iv = int8(value);
    if isOctaveRuntime()
        h5create(filename, path, 1, 'Datatype', 'int8');
        h5write(filename, path, iv);
    else
        lowLevelWriteScalarNumeric(filename, path, iv, 'H5T_STD_I8LE');
    end
    writeAttr(filename, path, '__pytype__', 'bool');
end
