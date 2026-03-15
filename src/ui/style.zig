const d2d1 = @import("../win32/d2d1.zig");
const dwrite = @import("../win32/dwrite.zig");

pub const Style = struct {
    text_color: ?*d2d1.ISolidColorBrush = null,
    background_color: ?*d2d1.ISolidColorBrush = null,
    border_color: ?*d2d1.ISolidColorBrush = null,
    font: Font = .{},
    text_align: dwrite.TEXT_ALIGNMENT = .CENTER,
    paragraph_align: dwrite.PARAGRAPH_ALIGNMENT = .CENTER,
};

pub const Font = struct {
    family: FontFamily = .NotoSansJP,
    size: FontSize = .Base,
    weight: FontWeight = .Normal,
};

pub const FontFamily = enum(u8) {
    NotoSansJP,
    SegoeUI,
};

pub const FontWeight = enum(u8) {
    Normal,
    Medium,
    Semibold,
    Bold,
};

pub const FontSize = enum(u8) {
    xs,
    sm,
    Base,
    lg,
    xl,
    xl2,
    xl3,
    xl4,
    xl5,
    xl6,
    xl7,
    xl8,
    xl9,
};
