function writeDict(filename, groupPath, value)
%WRITEDICT Write a scalar struct or containers.Map as a tome 'dict'
%   group. Keys are stringified and become HDF5 link names, so they must
%   be valid HDF5/MATLAB identifiers (no '/', no leading digit, etc.).
    if isa(value, 'containers.Map')
        keyList = keys(value);
        getValue = @(k) value(k);
    else
        keyList = fieldnames(value);
        getValue = @(k) value.(k);
    end

    if isempty(keyList)
        if isOctaveRuntime()
            error('tome:write:emptyDictUnsupportedInOctave', ...
                ['Cannot write an empty dict/struct group under Octave ' ...
                 '(hdf5oct has no low-level group-creation API). ' ...
                 'Add at least one field, or run under MATLAB.']);
        end
        lowLevelCreateGroup(filename, groupPath);
    else
        for i = 1:numel(keyList)
            k = keyList{i};
            writeNode(filename, joinPath(groupPath, k), getValue(k));
        end
    end

    writeAttr(filename, groupPath, '__pytype__', 'dict');
end
