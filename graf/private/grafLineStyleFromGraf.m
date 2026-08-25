function ls = grafLineStyleFromGraf(grafLineType)
%GRAFLINESTYLEFROMGRAF GrAF line_type string -> MATLAB LineStyle.
    switch grafLineType
        case {'-', '-.', ':', '--'}
            ls = grafLineType;
        otherwise
            ls = 'none';
    end
end
