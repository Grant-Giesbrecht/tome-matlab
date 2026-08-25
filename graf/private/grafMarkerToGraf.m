function mk = grafMarkerToGraf(matlabMarker)
%GRAFMARKERTOGRAF MATLAB marker code -> GrAF marker type string.
    switch matlabMarker
        case 'o',    mk = 'o';
        case '+',    mk = '+';
        case '^',    mk = '^';
        case 'v',    mk = 'v';
        case 's',    mk = '[]';
        case '.',    mk = '.';
        case 'x',    mk = 'x';
        case '*',    mk = '*';
        case '|',    mk = '|';
        case '_',    mk = '_';
        otherwise,   mk = 'None';
    end
end
