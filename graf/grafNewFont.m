function f = grafNewFont()
%GRAFNEWFONT Default Font struct, matching graf.base.Font()'s defaults.
    f = struct();
    f.use_native = false;
    f.size = 12;
    f.font = 'sanserif';
    f.bold = false;
    f.italic = false;
end
