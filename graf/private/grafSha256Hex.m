function h = grafSha256Hex(str)
%GRAFSHA256HEX Hex SHA-256 digest of a char string, via Java's
%   MessageDigest (available in MATLAB/Octave without any toolbox).
    try
        md = java.security.MessageDigest.getInstance('SHA-256');
        bytes = md.digest(uint8(str));
        h = lower(reshape(dec2hex(typecast(bytes, 'uint8'), 2)', 1, []));
    catch
        h = '';
    end
end
