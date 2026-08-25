function v = readAttrOr(filename, path, attrName, defaultVal)
%READATTROR h5readatt with a default value when the attribute (or the
%   node itself) is missing, so untagged/legacy HDF5 nodes stay readable.
    try
        v = h5readatt(filename, path, attrName);
        % Older MATLAB (e.g. R2019b) returns a vlen-string attribute as a
        % 1x1 cell array of char rather than a char/string directly.
        if iscell(v) && isscalar(v)
            v = v{1};
        end
        if isstring(v)
            v = char(v);
        end
    catch
        v = defaultVal;
    end
end
