function sf = grafNewSurface()
%GRAFNEWSURFACE Default Surface struct, matching graf.base.Surface()'s defaults.
    sf = struct();
    sf.surf_type = 'SURF_SURFACE';
    sf.cmap = [];

    sf.uniform_grid = false;
    sf.x_grid = [];
    sf.y_grid = [];
    sf.z_grid = [];
    sf.line_type = '-';
    sf.line_width = 1;
    sf.display_name = '';
    sf.include_in_legend = true;

    sf.line_color = [1 0 0];
    sf.alpha = 1;

    sf.antialias = false;

    sf.has_colorbar = false;
    sf.colorbar_label = '';
    sf.colorbar_orientation = 'vertical';
    sf.colorbar_ticks = [];
    sf.colorbar_tick_labels = {};
    sf.colorbar_vmin = NaN;
    sf.colorbar_vmax = NaN;
end
