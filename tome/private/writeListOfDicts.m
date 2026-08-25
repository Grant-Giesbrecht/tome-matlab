function writeListOfDicts(filename, groupPath, items)
%WRITELISTOFDICTS Write a cell array of dict-likes as a tome
%   'list_of_dicts' group of indexed subgroups "0", "1", ...
    if isempty(items)
        if isOctaveRuntime()
            error('tome:write:emptyListOfDictsUnsupportedInOctave', ...
                ['Cannot write an empty list-of-dicts group under Octave ' ...
                 '(hdf5oct has no low-level group-creation API). ' ...
                 'Add at least one element, or run under MATLAB.']);
        end
        lowLevelCreateGroup(filename, groupPath);
    else
        for i = 1:numel(items)
            writeDict(filename, joinPath(groupPath, sprintf('%d', i - 1)), items{i});
        end
    end

    writeAttr(filename, groupPath, '__pytype__', 'list_of_dicts');
end
