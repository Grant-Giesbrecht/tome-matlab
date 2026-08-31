function loc = grafLegendLocationFromGraf(grafLocation)
%GRAFLEGENDLOCATIONFROMGRAF GrAF legend_location -> MATLAB Legend.Location.
%   Inverse of grafLegendLocationToGraf.m. GrAF locations with no direct
%   MATLAB compass equivalent ("center", "center right") fall back to the
%   nearest inside location.
    switch grafLocation
        case 'best';          loc = 'best';
        case 'upper right';   loc = 'northeast';
        case 'upper left';    loc = 'northwest';
        case 'lower left';    loc = 'southwest';
        case 'lower right';   loc = 'southeast';
        case 'right';         loc = 'east';
        case 'center left';   loc = 'west';
        case 'center right';  loc = 'east';
        case 'lower center';  loc = 'south';
        case 'upper center';  loc = 'north';
        case 'center';        loc = 'best';
        otherwise;             loc = 'best';
    end
end
