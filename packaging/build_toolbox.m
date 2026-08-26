function outFile = build_toolbox(varargin)
%BUILD_TOOLBOX Package tome-matlab as a .mltbx for distribution (MATLAB
%   Add-On installer / File Exchange). Fully scripted via
%   matlab.addons.toolbox.ToolboxOptions -- no .prj project file, no GUI.
%
%   outFile = build_toolbox()
%   outFile = build_toolbox('OutputFile', '/path/to/out.mltbx')
%
%   The version comes from the repo-root VERSION file, and the toolbox
%   identifier from toolbox_identifier.txt next to this script -- that
%   identifier MUST stay the same across every release (it is how the
%   MATLAB Add-On manager recognizes "this is an update", not a new,
%   separate install); never regenerate it.
%
%   Requires MATLAB R2023a+ to *build* (matlab.addons.toolbox.
%   ToolboxOptions was introduced then). The resulting .mltbx itself
%   still targets MinimumMatlabRelease below, and installs fine on older
%   MATLAB -- only building it needs a recent MATLAB.
%
%   Octave has no toolbox/Add-On concept; Octave users should use
%   install.m (editable mode) instead. See also install.m, README.md.
    if verLessThan_local('9.14')   % R2023a; see local helper below
        error('build_toolbox:matlabTooOld', ...
            'Building a .mltbx requires MATLAB R2023a or later (matlab.addons.toolbox.ToolboxOptions). This MATLAB is older; run this on a newer install.');
    end

    p = inputParser();
    p.addParameter('OutputFile', '');
    p.parse(varargin{:});

    here = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(here);

    versionStr = strtrim(fileread(fullfile(repoRoot, 'VERSION')));
    identifier = strtrim(fileread(fullfile(here, 'toolbox_identifier.txt')));

    if isempty(p.Results.OutputFile)
        outFile = fullfile(here, 'dist', sprintf('tome-matlab-%s.mltbx', versionStr));
    else
        outFile = p.Results.OutputFile;
    end
    outDir = fileparts(outFile);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    opts = matlab.addons.toolbox.ToolboxOptions(repoRoot, identifier);
    opts.ToolboxName = 'tome-matlab';
    opts.ToolboxVersion = versionStr;
    opts.AuthorName = 'Grant Giesbrecht';
    opts.Summary = 'MATLAB/Octave reader-writer for the tome (HDF5 dict) and GrAF (figure archive) formats.';
    opts.Description = fileread(fullfile(repoRoot, 'README.md'));
    opts.MinimumMatlabRelease = 'R2019b';
    opts.ToolboxMatlabPath = {fullfile(repoRoot, 'tome'), fullfile(repoRoot, 'graf')};
    opts.ToolboxFiles = collectToolboxFiles(repoRoot);
    opts.OutputFile = outFile;

    matlab.addons.toolbox.packageToolbox(opts);
    fprintf('Packaged %s v%s -> %s\n', opts.ToolboxName, versionStr, outFile);
end

function files = collectToolboxFiles(repoRoot)
%COLLECTTOOLBOXFILES Only the library source (tome/, graf/, including
%   private/) plus README/LICENSE -- explicitly enumerated rather than
%   letting ToolboxOptions auto-scan the whole repo, since graf/ also
%   has scratch .graf/.fig files from manual testing that must not ship.
    files = [listMFiles(fullfile(repoRoot, 'tome')), ...
             listMFiles(fullfile(repoRoot, 'graf')), ...
             {fullfile(repoRoot, 'README.md'), fullfile(repoRoot, 'LICENSE')}];
end

function files = listMFiles(d)
    items = dir(fullfile(d, '**', '*.m'));
    files = arrayfun(@(x) fullfile(x.folder, x.name), items, 'UniformOutput', false)';
end

function tf = verLessThan_local(minVersionStr)
    v = ver('MATLAB');
    if isempty(v)
        tf = true;   % not MATLAB at all (e.g. Octave) -- can't build here
        return
    end
    tf = isMATLABReleaseOlderThan(v(1).Version, minVersionStr);
end

function tf = isMATLABReleaseOlderThan(haveVersion, wantVersion)
    a = sscanf(haveVersion, '%d.%d'); a = [a; 0; 0];
    b = sscanf(wantVersion, '%d.%d'); b = [b; 0; 0];
    tf = (a(1) < b(1)) || (a(1) == b(1) && a(2) < b(2));
end
