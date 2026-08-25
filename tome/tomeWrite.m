function ok = tomeWrite(data, filename, varargin)
%TOMEWRITE Write a struct (or containers.Map), or a cell array/struct
%   array of such dict-likes, to an HDF5 file in the tome format.
%
%   ok = tomeWrite(data, filename)
%
%   Supported value types (see README.md for the full mapping table):
%     scalar struct / containers.Map  -> tome 'dict' (a group)
%     cell array of dict-likes,
%       or a non-scalar struct array  -> tome 'list_of_dicts'
%     cell array of char/string,
%       or a non-scalar string array  -> tome 'list' of strings
%     numeric/logical array           -> tome 'ndarray'
%     char row vector / scalar string -> tome 'str'
%     logical scalar                  -> tome 'bool'
%     numeric scalar (real or complex)-> tome scalar number
%     anything else                   -> JSON fallback via jsonencode
%
%   Returns true on success, false on failure (mirroring the Python
%   dict_to_tome/tome_to_dict convention of signalling failure by
%   return value rather than by raising). Diagnostic text is emitted via
%   warning() on failure.
%
%   Name-value options:
%     'ShowDetail' (false) - print each top-level key as it is written.

    p = inputParser();
    p.addParameter('ShowDetail', false);
    p.parse(varargin{:});
    showDetail = p.Results.ShowDetail; %#ok<NASGU> (reserved for future use)

    ok = true;
    try
        if exist(filename, 'file')
            delete(filename);
        end

        if ~isOctaveRuntime()
            % Pre-create the file so low-level scalar/complex writes (and
            % writeAttr on an empty root) always have somewhere to land,
            % regardless of which child is written first.
            fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5F.close(fid);
        end

        isListRoot = (iscell(data) && ~isempty(data) && all(cellfun(@isDictLike, data))) || ...
                     (isstruct(data) && ~isscalar(data) && ~isempty(data));

        if isListRoot
            if isstruct(data)
                items = num2cell(data);
            else
                items = data;
            end
            writeListOfDicts(filename, '/', items);
        elseif isDictLike(data)
            writeDict(filename, '/', data);
        else
            error('tome:write:invalidRoot', ...
                ['Root data must be a scalar struct, a containers.Map, a cell ' ...
                 'array of such dict-likes, or a non-scalar struct array.']);
        end
    catch e
        warning('tome:write:failed', 'Failed to write tome file: %s', e.message);
        ok = false;
    end
end
