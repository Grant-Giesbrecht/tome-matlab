function install(varargin)
%INSTALL Add tome-matlab to the path in "editable" mode, for development
%   straight out of a git checkout -- no toolbox packaging, no Add-On
%   installation, just addpath on the library folders (like `pip install
%   -e`). Works under both MATLAB and Octave.
%
%   install()             Adds tome/ and graf/ to the path for this
%                          session only.
%   install('Save', true) Also calls savepath(), so the path change
%                          persists across future sessions.
%
%   For a redistributable, self-installing package instead (MATLAB Add-On
%   / File Exchange), see packaging/build_toolbox.m.
    p = inputParser();
    p.addParameter('Save', false);
    p.parse(varargin{:});

    here = fileparts(mfilename('fullpath'));
    addpath(fullfile(here, 'tome'));
    addpath(fullfile(here, 'graf'));

    if p.Results.Save
        if savepath() ~= 0
            warning('install:savepathFailed', ...
                ['Could not save the updated path (pathdef.m/octaverc may not ' ...
                 'be writable). The path is set for this session only -- call ' ...
                 'install() again next session, or run savepath() manually.']);
        end
    end

    fprintf('tome-matlab added to the path (%s).\n', here);
end
