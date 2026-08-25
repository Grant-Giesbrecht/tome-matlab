function sc = grafNewScale(varargin)
%GRAFNEWSCALE Default Scale struct, matching graf.base.Scale()'s defaults.
%   sc = grafNewScale()               -> is_valid = true
%   sc = grafNewScale('Valid', false) -> an unused axis (e.g. Z on a 2-D plot)
    p = inputParser();
    p.addParameter('Valid', true);
    p.parse(varargin{:});

    sc = struct();
    sc.is_valid = logical(p.Results.Valid);
    sc.val_min = 0;
    sc.val_max = 1;
    sc.tick_list = [];
    sc.minor_tick_list = [];
    sc.tick_label_list = {};
    sc.label = '';
    sc.scale_type = 'linear';
end
