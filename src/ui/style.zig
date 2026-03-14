const d2d1 = @import("../win32/d2d1.zig");

const FontWeight = enum {
    Normal,
    Semibold,
    Bold,
};

pub const Style = struct {
    color: *d2d1.ISolidColorBrush,
    font_family: []const u8 = "Segoe UI",
    font_size: f32 = 14.0,
    font_weight: FontWeight = .Normal,
};

pub const PartialStyle = struct {
    color: ?*d2d1.ISolidColorBrush = null,
    border_color: ?*d2d1.ISolidColorBrush = null,
};
