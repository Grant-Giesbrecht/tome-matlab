function f = grafNewFont()
%GRAFNEWFONT Default Font struct, matching graf.base.Font()'s defaults.
%   family is a font STACK (ordered candidates, most specific first,
%   ending in a generic role: "serif" | "sans-serif" | "monospace").
%   weight is 100-900 (400 normal, 700 bold); style is
%   "normal" | "italic" | "oblique". resolved_family records the typeface
%   actually in use when the file was written (filled in by the writer,
%   not the reader).
    f = struct();
    f.use_native = false;
    f.size = 12;
    f.family = {'sans-serif'};
    f.weight = 400;
    f.style = 'normal';
    f.resolved_family = '';
end
