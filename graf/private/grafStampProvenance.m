function g = grafStampProvenance(g, varargin)
%GRAFSTAMPPROVENANCE Populate info.provenance (once) and append a
%   info.history entry, mirroring Python's Graf._stamp_provenance /
%   write_graf choke point. Called by writegraf on every save.
    p = inputParser();
    p.addParameter('SourceApp', '');
    p.addParameter('Action', '');
    p.parse(varargin{:});
    sourceApp = p.Results.SourceApp;
    action = p.Results.Action;

    now = grafUtcNowIso();

    if ~isfield(g.info, 'provenance') || ~isstruct(g.info.provenance)
        g.info.provenance = struct();
    end
    if ~isfield(g.info, 'history') || ~iscell(g.info.history)
        g.info.history = {};
    end

    if isempty(fieldnames(g.info.provenance))
        prov = struct();
        prov.provenance_schema = '1.0';
        prov.created_utc = now;
        prov.created_by = sprintf('GrAF 0.1.0 (%s)', graf_source_runtime());
        prov.graf_format_version = '1.0';
        prov.graf_library_version = '0.1.0';
        prov.source_language = g.info.source_language;
        prov.creating_script = '';
        if ~isempty(sourceApp)
            prov.created_by_app = sourceApp;
        end
        try
            [status, hostname] = system('hostname');
            if status == 0
                prov.hostname = strtrim(hostname);
            else
                prov.hostname = '';
            end
        catch
            prov.hostname = '';
        end
        prov.os_platform = computer('arch');
        prov.machine_arch = computer('arch');
        g.info.provenance = prov;
    end

    try
        contentHash = grafSha256Hex(jsonencode(g));
    catch
        contentHash = '';
    end
    entry = struct();
    entry.utc = now;
    if isempty(action)
        if isempty(g.info.history)
            entry.action = 'created';
        else
            entry.action = 'saved';
        end
    else
        entry.action = action;
    end
    entry.by = sprintf('GrAF 0.1.0 (%s)', graf_source_runtime());
    entry.content_sha256 = contentHash;
    if ~isempty(sourceApp)
        entry.app = sourceApp;
    end
    g.info.history{end + 1} = entry;
end

function r = graf_source_runtime()
    if exist('OCTAVE_VERSION', 'builtin')
        r = ['Octave ' OCTAVE_VERSION()];
    else
        r = ['MATLAB ' version()];
    end
end
