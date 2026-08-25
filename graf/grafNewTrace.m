function tr = grafNewTrace()
%GRAFNEWTRACE Default Trace struct, matching graf.base.Trace()'s defaults.
    tr = struct();
    tr.trace_type = 'TRACE_LINE2D';
    tr.use_yaxis_R = false;
    tr.x_data = [];
    tr.y_data = [];
    tr.z_data = [];
    tr.line_type = '-';
    tr.marker_type = '.';
    tr.marker_size = 1;
    tr.line_width = 1;
    tr.display_name = '';
    tr.include_in_legend = true;

    tr.line_color = [1 0 0];
    tr.alpha = 1;
    tr.marker_color = [1 0 0];

    tr.has_error_bars = false;
    tr.x_err_neg = [];
    tr.x_err_pos = [];
    tr.y_err_neg = [];
    tr.y_err_pos = [];
    tr.err_line_color = [0.5 0.5 0.5];
    tr.err_line_width = 1.0;
    tr.err_cap_size = 3.0;
    tr.err_cap_color = [0.5 0.5 0.5];
    tr.err_cap_width = 1.0;
    tr.err_cap_visible = true;
end
