function s = grafUtcNowIso()
%GRAFUTCNOWISO ISO-8601 UTC timestamp, e.g. '2026-08-25T14:22:05+00:00'.
%   Octave has no 'datetime' without an extra package, but has 'time'/
%   'gmtime'/'strftime' as core builtins; MATLAB has the reverse. Use
%   whichever the running platform actually has.
    if exist('OCTAVE_VERSION', 'builtin')
        s = [strftime('%Y-%m-%dT%H:%M:%S', gmtime(time())) '+00:00'];
    else
        t = datetime('now', 'TimeZone', 'UTC');
        t.Format = 'yyyy-MM-dd''T''HH:mm:ss';
        s = [char(t) '+00:00'];
    end
end
