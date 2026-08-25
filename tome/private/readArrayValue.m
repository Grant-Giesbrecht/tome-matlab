function v = readArrayValue(filename, path)
%READARRAYVALUE Reconstruct a tome 'ndarray' dataset.
    dtypeAttr = readAttrOr(filename, path, 'dtype', '');
    raw = h5read(filename, path);

    if strcmp(dtypeAttr, 'str')
        v = toCellstr(raw);
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
