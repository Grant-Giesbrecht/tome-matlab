function grafEnsureTomeOnPath()
%GRAFENSURETOMEONPATH Add the sibling tome/ package to the path if the
%   caller hasn't already, so graf/ works as a standalone addpath target.
    if exist('tomeWrite', 'file') ~= 2
        here = fileparts(mfilename('fullpath'));
        addpath(fullfile(here, '..', '..', 'tome'));
    end
end
