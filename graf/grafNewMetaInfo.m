function info = grafNewMetaInfo(varargin)
%GRAFNEWMETAINFO Default MetaInfo struct, matching graf.base.MetaInfo().
%   info = grafNewMetaInfo()
%   info = grafNewMetaInfo('Description', '...', 'Conditions', struct(...))
%
%   provenance/history start empty; grafSave stamps them (see
%   grafStampProvenance.m), matching Python's write_graf choke point.
    p = inputParser();
    p.addParameter('Description', '');
    p.addParameter('Conditions', struct());
    p.parse(varargin{:});

    info = struct();
    info.version = '0.0.0';
    info.source_language = 'MATLAB';
    info.source_library = 'GrAF';
    info.source_version = '0.0.0';
    info.description = p.Results.Description;
    info.conditions = p.Results.Conditions;
    info.provenance = struct();
    info.history = {};
end
