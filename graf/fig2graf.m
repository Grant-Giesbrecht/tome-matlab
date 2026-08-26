function fig2graf(fh, output)
    
    % If input is not a handle, try to open it (assume it's a file)
    if ~isgraphics(fh, 'figure')
        try
            fh = openfig(fh);
            
            % If input is not a handle, error out
            if ~isgraphics(fh, 'figure')
                disp("Invalid input. Must be figure handle or .fig file");
                return
            end
        catch
            disp("Invalid input. Must be figure handle or .fig file");
            return
        end
    end
    
    % Create graf struct
    graf = grafFromFig(fh);
    
    % Save graf file
    grafSave(fh, output);
    
end