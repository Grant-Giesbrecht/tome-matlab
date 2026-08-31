function grafCheckFormatVersion(versionStr)
%GRAFCHECKFORMATVERSION Enforce FORMAT.md's versioning contract.
%   A file whose MAJOR differs from this reader's is refused, except the
%   pre-1.0 ("0.x", declared "0.0.0") legacy layout, which this reader
%   tolerates via field defaults rather than a version check (see
%   FORMAT.md section 11 — there is no migration code, none is needed). A
%   newer MINOR warns but proceeds; same-or-older is silent.
    OUR_MAJOR = 1;
    OUR_MINOR = 0;

    parts = strsplit(versionStr, '.');
    fileMajor = str2double(parts{1});
    if numel(parts) > 1
        fileMinor = str2double(parts{2});
    else
        fileMinor = 0;
    end
    if isnan(fileMajor); fileMajor = 0; end
    if isnan(fileMinor); fileMinor = 0; end

    if fileMajor == 0
        return   % pre-1.0 legacy layout; loaded via field defaults, not refused
    end
    if fileMajor ~= OUR_MAJOR
        error('graf:read:versionMismatch', ...
            ['Cannot read a GrAF file with format version %s: this reader ' ...
             'supports format %d.%d.'], versionStr, OUR_MAJOR, OUR_MINOR);
    end
    if fileMinor > OUR_MINOR
        warning('graf:read:newerMinorVersion', ...
            ['This file was written with a newer format minor version (%s) ' ...
             'than this reader supports (%d.%d). Fields added after %d.%d ' ...
             'will be ignored.'], versionStr, OUR_MAJOR, OUR_MINOR, OUR_MAJOR, OUR_MINOR);
    end
end
