function gs = grafFillGraphStyleDefaults(gs)
%GRAFFILLGRAPHSTYLEDEFAULTS Ensure a style struct has all five font slots
%   (pre-1.0 files have no legend_font) and that every Font present has
%   the format-1.0 fields, migrating around any pre-1.0 layout (see
%   grafFillFontDefaults.m / FORMAT.md section 11).
    fontFields = {'supertitle_font', 'title_font', 'graph_font', ...
                  'label_font', 'legend_font'};
    for i = 1:numel(fontFields)
        fn = fontFields{i};
        if ~isfield(gs, fn) || ~isstruct(gs.(fn))
            gs.(fn) = grafNewFont();
        else
            gs.(fn) = grafFillFontDefaults(gs.(fn));
        end
    end
end
