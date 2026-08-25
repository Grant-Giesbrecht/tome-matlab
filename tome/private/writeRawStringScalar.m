function writeRawStringScalar(filename, path, s)
%WRITERAWSTRINGSCALAR Write a true scalar (0-D) vlen UTF-8 string
%   dataset with no attributes; callers set '__pytype__' afterwards.
    if isOctaveRuntime()
        h5create(filename, path, 1, 'Datatype', 'string');
        h5write(filename, path, s);
    else
        lowLevelWriteScalarString(filename, path, s);
    end
end
