const std = @import("std");
const Style = @import("ui/style.zig").Style;
const d2d1 = @import("win32/d2d1.zig");
const vhr = @import("win32/win32.zig").vhr;
const dwrite = @import("win32/dwrite.zig");
const DrawingContext = @import("drawing.zig").DrawingContext;

const L = std.unicode.utf8ToUtf16LeStringLiteral;

pub const RectSize = struct {
    width: f32,
    height: f32,
};

pub const Size = union(enum) {
    Fixed: f32, // take up exactly this many DIPs
    Flex: f32, // take up this fraction of remaining space (like flex: 1)
    Hug, // value returned by measure()
};

pub const Widget = union(enum) {
    vstack: VStack,
    text: Text,

    pub fn width(self: Widget) Size {
        return switch (self) {
            inline else => |w| w.width,
        };
    }

    pub fn height(self: Widget) Size {
        return switch (self) {
            inline else => |w| w.height,
        };
    }

    pub fn measure(self: *const Widget, allocator: std.mem.Allocator, ctx: *const DrawingContext, available: d2d1.RECT_F) RectSize {
        switch (self.*) {
            .vstack => |v| {
                var total_height: f32 = 0;
                var max_width: f32 = 0;
                for (v.children) |child| {
                    const child_size = child.measure(allocator, ctx, available);
                    total_height += child_size.height; // + v.gap;
                    max_width = @max(max_width, child_size.width);
                }
                return .{ .width = max_width, .height = total_height };
            },
            .text => |t| {
                const text_w = std.unicode.utf8ToUtf16LeAllocZ(allocator, t.text) catch |e| switch (e) {
                    error.InvalidUtf8 => L("Invalid UTF-8"),
                    error.OutOfMemory => @panic("Out of memory"),
                };

                const text_format = ctx.getTextFormat(t.style.font) orelse ctx.noto_normal_sm;
                vhr(text_format.SetTextAlignment(.CENTER));
                vhr(text_format.SetParagraphAlignment(.CENTER));

                var text_layout: *dwrite.ITextLayout = undefined;
                vhr(ctx.dw.CreateTextLayout(
                    text_w.ptr,
                    @intCast(text_w.len),
                    text_format,
                    available.width(),
                    available.height(),
                    @ptrCast(&text_layout),
                ));
                defer _ = text_layout.Release();

                var metrics: dwrite.TEXT_METRICS = undefined;
                vhr(text_layout.GetMetrics(&metrics));

                return RectSize{
                    .width = metrics.width,
                    .height = metrics.height,
                };
            },
        }
    }

    pub fn layout(self: *Widget, allocator: std.mem.Allocator, ctx: *const DrawingContext, available: d2d1.RECT_F) void {
        switch (self.*) {
            .vstack => |*v| {
                // 1. measure all non-flex children
                var fixed_height: f32 = 0;
                var total_flex: f32 = 0;
                for (v.children) |*child| {
                    switch (child.height()) {
                        .Flex => |flex| total_flex += flex,
                        else => fixed_height += child.measure(allocator, ctx, available).height, // + v.gap,
                    }
                }

                // 2. divide remaining space among flex children
                const remaining = available.height() - fixed_height;
                var cursor: f32 = available.top;
                for (v.children) |*child| {
                    const child_h = switch (child.height()) {
                        .Fixed => |px| px,
                        .Hug => child.measure(allocator, ctx, available).height,
                        .Flex => |flex_grow| remaining * (flex_grow / total_flex),
                    };
                    child.layout(allocator, ctx, .{
                        .left = available.left,
                        .top = cursor, // determined by vstack
                        .right = available.right,
                        .bottom = cursor + child_h, // determined by vstack
                    });
                    cursor += child_h; //  + v.gap;
                }
                v.layout_rect = available;
            },
            .text => |*t| {
                t.layout_rect = available;
            },
        }
    }

    pub fn render(self: *const Widget, allocator: std.mem.Allocator, ctx: *const DrawingContext) void {
        switch (self.*) {
            .vstack => |v| v.render(allocator, ctx),
            .text => |t| t.render(allocator, ctx),
        }
    }
};

pub const VStack = struct {
    children: []Widget = &[0]Widget{},
    width: Size = .Hug,
    height: Size = .Hug,
    style: Style = .{},

    // dynamically computed in update() loop via widget.layout()
    layout_rect: d2d1.RECT_F = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },

    pub fn render(self: *const VStack, allocator: std.mem.Allocator, ctx: *const DrawingContext) void {
        if (self.style.background_color) |color| {
            ctx.r.FillRectangle(&self.layout_rect, @ptrCast(color));
        }
        for (self.children) |child| {
            child.render(allocator, ctx);
        }
    }
};

pub const Text = struct {
    text: []const u8,
    width: Size = .Hug,
    height: Size = .Hug,
    style: Style = .{},

    // dynamically computed in update() loop via widget.layout()
    layout_rect: d2d1.RECT_F = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },

    pub fn render(self: *const Text, allocator: std.mem.Allocator, ctx: *const DrawingContext) void {
        const text_w = std.unicode.utf8ToUtf16LeAllocZ(allocator, self.text) catch |e| switch (e) {
            error.InvalidUtf8 => L("Invalid UTF-8"),
            error.OutOfMemory => @panic("Out of memory"),
        };

        const text_format = ctx.getTextFormat(self.style.font) orelse ctx.noto_normal_sm;
        vhr(text_format.SetTextAlignment(.CENTER));
        vhr(text_format.SetParagraphAlignment(.CENTER));

        ctx.r.DrawText(
            text_w.ptr,
            @intCast(text_w.len),
            text_format,
            &self.layout_rect,
            @ptrCast(self.style.text_color orelse ctx.slate50),
            .{},
            .NATURAL,
        );
    }
};
