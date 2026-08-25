function mk = grafMarkerFromGraf(grafMarker)
%GRAFMARKERFROMGRAF GrAF marker type string -> MATLAB marker code.
    switch grafMarker
        case 'o',    mk = 'o';
        case '+',    mk = '+';
        case '^',    mk = '^';
        case 'v',    mk = 'v';
        case '[]',   mk = 's';
        case '.',    mk = '.';
        case 'x',    mk = 'x';
        case '*',    mk = '*';
        case '|',    mk = '|';
        case '_',    mk = '_';
        otherwise,   mk = 'none';
    end
end
