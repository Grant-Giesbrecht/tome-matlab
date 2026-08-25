function writeStringList(filename, path, values)
%WRITESTRINGLIST Write a non-empty cell array of char/string scalars as
%   a tome 'list' of strings (1-D vlen UTF-8 dataset).
    n = numel(values);
    strs = cell(n, 1);
    for k = 1:n
        strs{k} = char(values{k});
    end

    if isOctaveRuntime()
        h5create(filename, path, n, 'Datatype', 'string');
        h5write(filename, path, strs);
    else
        % h5create/h5write only gained 'Datatype','string' support around
        % R2020b; the low-level path works on much older MATLAB releases.
        lowLevelWriteStringArray(filename, path, strs);
    end
    writeAttr(filename, path, '__pytype__', 'list');
    writeAttr(filename, path, 'dtype', 'str');
end
