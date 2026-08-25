function tf = isTextScalar(value)
%ISTEXTSCALAR True for a char row vector (or empty char) or a 1x1 string.
    tf = (ischar(value) && (isrow(value) || isempty(value))) || ...
         (isstring(value) && isscalar(value));
end
