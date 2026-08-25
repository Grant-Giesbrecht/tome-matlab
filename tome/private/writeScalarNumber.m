function writeScalarNumber(filename, path, value)
%WRITESCALARNUMBER Write a numeric (non-logical) scalar, real or
%   complex, as a tome scalar dataset tagged with its NumPy-style dtype
%   name (or 'complex128' for complex data).
    if ~isreal(value)
        writeComplexDataset(filename, path, value);
        writeAttr(filename, path, '__pytype__', 'complex128');
        return
    end

    cls = class(value);
    if isOctaveRuntime()
        octType = h5TypeStrings(cls);
        h5create(filename, path, 1, 'Datatype', octType);
        h5write(filename, path, value);
    else
        [~, lowLevelTypeId] = h5TypeStrings(cls);
        lowLevelWriteScalarNumeric(filename, path, value, lowLevelTypeId);
    end
    writeAttr(filename, path, '__pytype__', dtypeNameFromClass(cls));
end
