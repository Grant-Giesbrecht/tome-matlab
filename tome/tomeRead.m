function data = tomeRead(filename)
%TOMEREAD Read an HDF5 file written in the tome format back into a
%   MATLAB struct (or a 1xN cell array of structs, if that's what was
%   originally written as the root).
%
%   data = tomeRead(filename)
%
%   Returns [] if the file cannot be read or parsed (mirroring the
%   Python tome_to_dict convention of returning None on failure).
%   Diagnostic text is emitted via warning() on failure.
    try
        pytype = readAttrOr(filename, '/', '__pytype__', 'dict');
        if strcmp(pytype, 'list_of_dicts')
            data = readListOfDicts(filename, '/');
        else
            data = readDict(filename, '/');
        end
    catch e
        warning('tome:read:failed', 'Failed to read tome file: %s', e.message);
        data = [];
    end
end
