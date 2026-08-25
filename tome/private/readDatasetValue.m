function v = readDatasetValue(filename, path)
%READDATASETVALUE Reconstruct a MATLAB value from a tome dataset node,
%   dispatching on its '__pytype__' attribute (format.md section 6).
    pytype = readAttrOr(filename, path, '__pytype__', '');

    switch pytype
        case 'str'
            v = readScalarStringValue(filename, path);

        case 'bool'
            raw = h5read(filename, path);
            v = logical(raw(1) ~= 0);

        case 'json'
            s = readScalarStringValue(filename, path);
            v = jsondecode(s);

        case 'ndarray'
            v = readArrayValue(filename, path);

        case 'list'
            v = readListValue(filename, path);

        otherwise
            % Numeric scalar (numpy dtype name, 'int', 'float', 'complex',
            % 'complex128', ...) or an untagged/legacy dataset: decode
            % natively rather than treating an unrecognised tag as an error.
            raw = h5read(filename, path);
            if isstruct(raw) && isfield(raw, 'r') && isfield(raw, 'i')
                v = complex(raw.r(1), raw.i(1));
            elseif ischar(raw) || isstring(raw)
                v = char(raw);
            else
                if numel(raw) >= 1
                    v = raw(1);
                else
                    v = raw;
                end
            end
    end
end
