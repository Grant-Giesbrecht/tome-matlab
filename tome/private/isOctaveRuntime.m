function tf = isOctaveRuntime()
%ISOCTAVERUNTIME True when running under GNU Octave rather than MATLAB.
    persistent cached
    if isempty(cached)
        cached = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
    end
    tf = cached;
end
