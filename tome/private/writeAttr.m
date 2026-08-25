function writeAttr(filename, path, name, value)
%WRITEATTR Thin wrapper around h5writeatt, kept as a single choke point
%   in case platform-specific quirks need to be handled later.
    h5writeatt(filename, path, name, value);
end
