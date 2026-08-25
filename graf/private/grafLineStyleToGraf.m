function ls = grafLineStyleToGraf(matlabLineStyle)
%GRAFLINESTYLETOGRAF MATLAB LineStyle -> GrAF line_type string.
%   GrAF's LINE_TYPES = ["-", "-.", ":", "--", "None"] match MATLAB's
%   own line style strings exactly except for 'none'.
    switch matlabLineStyle
        case {'-', '-.', ':', '--'}
            ls = matlabLineStyle;
        otherwise
            ls = 'None';
    end
end
