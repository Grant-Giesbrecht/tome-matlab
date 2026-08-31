function loc = grafLegendLocationToGraf(matlabLocation)
%GRAFLEGENDLOCATIONTOGRAF MATLAB Legend.Location -> GrAF legend_location.
%   GrAF's LEGEND_LOCATIONS follow matplotlib's naming ("upper right",
%   ...); MATLAB's Location property uses compass points ("northeast",
%   ...). Outside/compound MATLAB locations that have no direct GrAF
%   counterpart fall back to the nearest inside location.
    switch lower(matlabLocation)
        case 'best';                     loc = 'best';
        case {'northeast', 'northeastoutside'};   loc = 'upper right';
        case {'northwest', 'northwestoutside'};   loc = 'upper left';
        case {'southwest', 'southwestoutside'};   loc = 'lower left';
        case {'southeast', 'southeastoutside'};   loc = 'lower right';
        case {'east', 'eastoutside'};             loc = 'right';
        case {'west', 'westoutside'};             loc = 'center left';
        case {'south', 'southoutside'};           loc = 'lower center';
        case {'north', 'northoutside'};           loc = 'upper center';
        otherwise;                        loc = 'best';
    end
end
