function s = readDict(filename, groupPath)
%READDICT Reconstruct a tome 'dict' group as a scalar MATLAB struct.
    info = h5info(filename, groupPath);
    s = struct();

    for i = 1:numel(info.Datasets)
        childPath = resolveChildPath(groupPath, info.Datasets(i).Name);
        key = basenamePath(childPath);
        s.(key) = readDatasetValue(filename, childPath);
    end

    for i = 1:numel(info.Groups)
        childPath = resolveChildPath(groupPath, info.Groups(i).Name);
        key = basenamePath(childPath);
        childPytype = readAttrOr(filename, childPath, '__pytype__', 'dict');
        if strcmp(childPytype, 'list_of_dicts')
            s.(key) = readListOfDicts(filename, childPath);
        else
            s.(key) = readDict(filename, childPath);
        end
    end
end
