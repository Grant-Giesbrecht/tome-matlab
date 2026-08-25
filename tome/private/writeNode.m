function writeNode(filename, path, value)
%WRITENODE Dispatch a single key/value pair onto an HDF5 node at PATH,
%   mirroring the tome format's writer algorithm (format.md section 5).
%   The order of checks matters: several branches overlap.

    if isDictLike(value)
        writeDict(filename, path, value);
        return
    end

    if (iscell(value) && ~isempty(value) && all(cellfun(@isDictLike, value))) || ...
       (isstruct(value) && ~isscalar(value) && ~isempty(value))
        if isstruct(value)
            items = num2cell(value);
        else
            items = value;
        end
        writeListOfDicts(filename, path, items);
        return
    end

    if (iscell(value) && ~isempty(value) && all(cellfun(@isTextScalar, value))) || ...
       (isstring(value) && ~isscalar(value) && ~isempty(value))
        if isstring(value)
            items = cellstr(value);
        else
            items = value;
        end
        writeStringList(filename, path, items);
        return
    end

    if (isnumeric(value) || islogical(value)) && ~isscalar(value)
        writeArray(filename, path, value);
        return
    end

    if isTextScalar(value)
        writeScalarString(filename, path, value);
        return
    end

    if islogical(value) && isscalar(value)
        writeScalarBool(filename, path, value);
        return
    end

    if isnumeric(value) && isscalar(value)
        writeScalarNumber(filename, path, value);
        return
    end

    writeScalarJSON(filename, path, value);
end
