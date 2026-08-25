function tf = isDictLike(value)
%ISDICTLIKE True for a scalar struct or a containers.Map (tome 'dict').
    tf = (isstruct(value) && isscalar(value)) || isa(value, 'containers.Map');
end
