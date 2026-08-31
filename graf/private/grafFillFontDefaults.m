function f = grafFillFontDefaults(f)
%GRAFFILLFONTDEFAULTS Fill in format-1.0 Font fields missing from a file
%   written by an older layout (see FORMAT.md section 11).
%
%   Pre-1.0 stored `font` (a string) / `bold` / `italic`; 1.0 stores
%   `family` (an ordered stack) / `weight` / `style` /
%   `resolved_family`. Per the format spec the old fields are ignored
%   outright rather than translated: turning a bare family name into a
%   stack, or a bool into a weight, would fabricate a preference the file
%   never recorded.
    if ~isfield(f, 'use_native');      f.use_native = false;        end
    if ~isfield(f, 'size');            f.size = 12;                 end
    if ~isfield(f, 'family');          f.family = {'sans-serif'};   end
    if ~isfield(f, 'weight');          f.weight = 400;              end
    if ~isfield(f, 'style');           f.style = 'normal';          end
    if ~isfield(f, 'resolved_family'); f.resolved_family = '';      end
end
