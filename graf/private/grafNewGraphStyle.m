function gs = grafNewGraphStyle()
%GRAFNEWGRAPHSTYLE Default GraphStyle struct, matching graf.base.GraphStyle().
    gs = struct();
    gs.supertitle_font = grafNewFont();
    gs.title_font = grafNewFont();
    gs.graph_font = grafNewFont();
    gs.label_font = grafNewFont();
end
