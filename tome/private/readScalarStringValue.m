function s = readScalarStringValue(filename, path)
%READSCALARSTRINGVALUE Read a tome scalar 'str'/'json' dataset as char.
    raw = h5read(filename, path);
    if iscell(raw)
        raw = raw{1};
    elseif isstring(raw)
        raw = raw(1);
    end
    s = char(raw);
    if isempty(s)
        s = '';
    end
end
