function writeAttr(filename, path, name, value)
%WRITEATTR Write a tome string attribute ('__pytype__', 'dtype', ...).
%   Octave's h5writeatt already writes vlen UTF-8 as h5py expects; on
%   MATLAB this goes through the low-level API instead (see
%   lowLevelWriteAttrString.m for why).
    if isOctaveRuntime()
        h5writeatt(filename, path, name, value);
    else
        lowLevelWriteAttrString(filename, path, name, value);
    end
end
