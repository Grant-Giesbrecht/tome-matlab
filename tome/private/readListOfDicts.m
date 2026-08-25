function items = readListOfDicts(filename, groupPath)
%READLISTOFDICTS Reconstruct a tome 'list_of_dicts' group as a 1xN cell
%   array of structs, ordered by the numeric value of the child names
%   ("0", "1", ... "10", ...), not lexicographically.
    info = h5info(filename, groupPath);
    names = {info.Groups.Name};
    indices = cellfun(@(n) str2double(basenamePath(n)), names);
    [~, order] = sort(indices);

    items = cell(1, numel(names));
    for i = 1:numel(names)
        items{i} = readDict(filename, names{order(i)});
    end
end
