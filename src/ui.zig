const std = @import("std");
const Style = @import("ui/style.zig").Style;
const d2d1 = @import("win32/d2d1.zig");
const vhr = @import("win32/win32.zig").vhr;
const DrawingContext = @import("drawing.zig").DrawingContext;

const L = std.unicode.utf8ToUtf16LeStringLiteral;

pub const Widget = union(enum) {
    vstack: VStack,
};

pub const VStack = struct {
    children: []Widget = &[0]Widget{},
    style: Style = .{},

    pub fn render(self: *const VStack, ctx: *const DrawingContext, rect: *const d2d1.RECT_F) void {
        if (self.style.background_color) |color| {
            ctx.r.FillRectangle(rect, @ptrCast(color));
        }
    }
};

pub const Text = struct {
    style: Style = .{},
    text: []const u8,

    pub fn render(self: *const Text, allocator: std.mem.Allocator, ctx: *const DrawingContext, rect: *const d2d1.RECT_F) void {
        const text = std.unicode.utf8ToUtf16LeAllocZ(allocator, self.text) catch |e| switch (e) {
            error.InvalidUtf8 => L("Invalid UTF-8"),
            error.OutOfMemory => @panic("Out of memory"),
        };

        const text_format = ctx.getTextFormat(self.style.font) orelse ctx.noto_normal_sm;
        vhr(text_format.SetTextAlignment(.CENTER));
        vhr(text_format.SetParagraphAlignment(.CENTER));

        ctx.r.DrawText(
            text.ptr,
            @intCast(text.len),
            text_format,
            rect,
            @ptrCast(self.style.text_color orelse ctx.slate50),
            .{},
            .NATURAL,
        );
    }
};
