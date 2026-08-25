function writeScalarString(filename, path, value)
%WRITESCALARSTRING Write a MATLAB char/string scalar as a tome 'str'.
    writeRawStringScalar(filename, path, char(value));
    writeAttr(filename, path, '__pytype__', 'str');
end
