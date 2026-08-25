function v = readListValue(filename, path)
%READLISTVALUE Reconstruct a tome 'list' dataset (numeric list, string
%   list, or per-element JSON-encoded mixed/ragged list). MATLAB has no
%   distinct list type, so numeric lists come back as plain arrays, the
%   same as 'ndarray' data.
    dtypeAttr = readAttrOr(filename, path, 'dtype', '');
    raw = h5read(filename, path);

    if strcmp(dtypeAttr, 'str')
        strs = toCellstr(raw);
        elemEncoding = readAttrOr(filename, path, 'elem_encoding', '');
        if strcmp(elemEncoding, 'json')
            v = cellfun(@jsondecode, strs, 'UniformOutput', false);
        else
            v = strs;
        end
        return
    end

    if isnumeric(raw) && isempty(raw)
        v = [];
        return
    end

    if strcmp(dtypeAttr, 'complex128')
        raw = combineComplexRaw(raw);
        v = reconstructArrayShape(raw);
        return
    end

    if strcmp(dtypeAttr, 'bool')
        v = reconstructArrayShape(decodeBoolArray(raw));
        return
    end

    v = reconstructArrayShape(raw);
    cls = classFromDtypeName(dtypeAttr);
    if ~isempty(cls)
        v = cast(v, cls);
    end
end
