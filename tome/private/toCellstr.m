function c = toCellstr(raw)
%TOCELLSTR Normalize whatever h5read hands back for a vlen string
%   dataset (char, cellstr, or a MATLAB string array, on either
%   platform) into a 1xN cell array of char row vectors.
    if ischar(raw)
        c = {raw};
    elseif isstring(raw)
        c = cellstr(raw(:).');
    elseif iscell(raw)
        c = cellfun(@char, raw(:).', 'UniformOutput', false);
    else
        c = {raw};
    end
end
