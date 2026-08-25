function v = readAttrOr(filename, path, attrName, defaultVal)
%READATTROR h5readatt with a default value when the attribute (or the
%   node itself) is missing, so untagged/legacy HDF5 nodes stay readable.
    try
        v = h5readatt(filename, path, attrName);
        if isstring(v)
            v = char(v);
        end
    catch
        v = defaultVal;
    end
end
