function writeScalarJSON(filename, path, value)
%WRITESCALARJSON Fallback path: JSON-encode VALUE into a scalar vlen
%   UTF-8 string dataset tagged 'json', matching the tome format's
%   catch-all for values with no dedicated encoding.
    s = jsonencode(value);
    writeRawStringScalar(filename, path, s);
    writeAttr(filename, path, '__pytype__', 'json');
end
