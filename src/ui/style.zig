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
    family: []const u8 = "Segoe UI",
    size: FontSize = .Base,
    weight: FontWeight = .Normal,
};

pub const FontWeight = enum(u8) {
    Normal,
    Medium,
    Bold,
};

pub const FontSize = enum(u8) {
    XS,
    SM,
    Base,
    LG,
    XL,
    XL2,
    XL3,
    XL4,
    XL5,
    XL6,
    XL7,
    XL8,
    XL9,
};
