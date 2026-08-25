function p = joinPath(groupPath, name)
%JOINPATH Join an HDF5 group path and a child name, avoiding a doubled
%   leading slash when groupPath is the root ("/").
    if strcmp(groupPath, '/')
        p = ['/' name];
    else
        p = [groupPath '/' name];
    end
end
