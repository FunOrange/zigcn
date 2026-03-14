const Style = @import("style.zig").Style;
const PartialStyle = @import("style.zig").PartialStyle;
const Widget = @import("widget.zig").Widget;
const d2d1 = @import("../win32/d2d1.zig");
const vhr = @import("../win32/win32.zig").vhr;
const DrawingContext = @import("../drawing.zig").DrawingContext;

pub const VStack = struct {
    children: []Widget = &[0]Widget{},
    style: PartialStyle = .{},

    pub fn render(self: *const VStack, ctx: *const DrawingContext, rect: *const d2d1.RECT_F) void {
        ctx.r.FillRectangle(rect, @ptrCast(self.style.color.?));
    }
};
