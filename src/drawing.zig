const std = @import("std");
const w32 = @import("win32/win32.zig");
const d2d1 = @import("win32/d2d1.zig");
const dwrite = @import("win32/dwrite.zig");
const ui = @import("ui.zig");
const LruCache = @import("data-structures.zig").LruCache;

const L = std.unicode.utf8ToUtf16LeStringLiteral;

const noto = L("Noto Sans JP");

const BRUSH_CACHE_SIZE = 128;
const TEXT_FORMAT_CACHE_SIZE = 128;

const BrushManager = struct {
    cache: *LruCache(*d2d1.ISolidColorBrush, BRUSH_CACHE_SIZE),
    rt: *d2d1.IHwndRenderTarget,

    pub fn init(allocator: std.mem.Allocator, rt: *d2d1.IHwndRenderTarget) BrushManager {
        const cache = allocator.create(LruCache(*d2d1.ISolidColorBrush, BRUSH_CACHE_SIZE)) catch unreachable;
        cache.* = LruCache(*d2d1.ISolidColorBrush, BRUSH_CACHE_SIZE).init(allocator);
        return .{
            .cache = cache,
            .rt = rt,
        };
    }

    pub fn get(self: *BrushManager, comptime hex: []const u8) *d2d1.ISolidColorBrush {
        if (self.cache.get(hex)) |brush| {
            return brush;
        }
        const brush = createBrush(self.rt, hex);
        if (self.cache.put(hex, brush) catch unreachable) |evicted| {
            _ = evicted.Release();
        }
        return brush;
    }

    pub fn deinit(self: *BrushManager) void {
        var iter = self.cache.map.iterator();
        while (iter.next()) |entry| {
            const brush = entry.value_ptr.value;
            _ = brush.Release();
        }
        self.cache.deinit();
    }
};

pub const DrawingContext = struct {
    r: *d2d1.IHwndRenderTarget,
    dw: *dwrite.IFactory,

    // brushes
    brushes: BrushManager,

    // fonts
    noto_normal_xs: *dwrite.ITextFormat,
    noto_normal_sm: *dwrite.ITextFormat,
    noto_normal_base: *dwrite.ITextFormat,
    noto_normal_lg: *dwrite.ITextFormat,
    noto_normal_xl: *dwrite.ITextFormat,
    noto_normal_2xl: *dwrite.ITextFormat,
    noto_normal_3xl: *dwrite.ITextFormat,
    noto_normal_4xl: *dwrite.ITextFormat,
    noto_normal_5xl: *dwrite.ITextFormat,
    noto_normal_6xl: *dwrite.ITextFormat,
    noto_normal_7xl: *dwrite.ITextFormat,
    noto_normal_8xl: *dwrite.ITextFormat,
    noto_normal_9xl: *dwrite.ITextFormat,
    noto_medium_xs: *dwrite.ITextFormat,
    noto_medium_sm: *dwrite.ITextFormat,
    noto_medium_base: *dwrite.ITextFormat,
    noto_medium_lg: *dwrite.ITextFormat,
    noto_medium_xl: *dwrite.ITextFormat,
    noto_medium_2xl: *dwrite.ITextFormat,
    noto_medium_3xl: *dwrite.ITextFormat,
    noto_medium_4xl: *dwrite.ITextFormat,
    noto_medium_5xl: *dwrite.ITextFormat,
    noto_medium_6xl: *dwrite.ITextFormat,
    noto_medium_7xl: *dwrite.ITextFormat,
    noto_medium_8xl: *dwrite.ITextFormat,
    noto_medium_9xl: *dwrite.ITextFormat,
    noto_bold_xs: *dwrite.ITextFormat,
    noto_bold_sm: *dwrite.ITextFormat,
    noto_bold_base: *dwrite.ITextFormat,
    noto_bold_lg: *dwrite.ITextFormat,
    noto_bold_xl: *dwrite.ITextFormat,
    noto_bold_2xl: *dwrite.ITextFormat,
    noto_bold_3xl: *dwrite.ITextFormat,
    noto_bold_4xl: *dwrite.ITextFormat,
    noto_bold_5xl: *dwrite.ITextFormat,
    noto_bold_6xl: *dwrite.ITextFormat,
    noto_bold_7xl: *dwrite.ITextFormat,
    noto_bold_8xl: *dwrite.ITextFormat,
    noto_bold_9xl: *dwrite.ITextFormat,

    pub fn init(allocator: std.mem.Allocator, dw: *dwrite.IFactory, rt: *d2d1.IHwndRenderTarget) DrawingContext {
        var ctx = DrawingContext{
            .r = rt,
            .dw = dw,
            .brushes = undefined,
            .noto_normal_xs = createTextFormat(dw, noto, 12.0, .NORMAL),
            .noto_normal_sm = createTextFormat(dw, noto, 14.0, .NORMAL),
            .noto_normal_base = createTextFormat(dw, noto, 16.0, .NORMAL),
            .noto_normal_lg = createTextFormat(dw, noto, 18.0, .NORMAL),
            .noto_normal_xl = createTextFormat(dw, noto, 20.0, .NORMAL),
            .noto_normal_2xl = createTextFormat(dw, noto, 24.0, .NORMAL),
            .noto_normal_3xl = createTextFormat(dw, noto, 30.0, .NORMAL),
            .noto_normal_4xl = createTextFormat(dw, noto, 36.0, .NORMAL),
            .noto_normal_5xl = createTextFormat(dw, noto, 48.0, .NORMAL),
            .noto_normal_6xl = createTextFormat(dw, noto, 60.0, .NORMAL),
            .noto_normal_7xl = createTextFormat(dw, noto, 72.0, .NORMAL),
            .noto_normal_8xl = createTextFormat(dw, noto, 96.0, .NORMAL),
            .noto_normal_9xl = createTextFormat(dw, noto, 128.0, .NORMAL),
            .noto_medium_xs = createTextFormat(dw, noto, 12.0, .MEDIUM),
            .noto_medium_sm = createTextFormat(dw, noto, 14.0, .MEDIUM),
            .noto_medium_base = createTextFormat(dw, noto, 16.0, .MEDIUM),
            .noto_medium_lg = createTextFormat(dw, noto, 18.0, .MEDIUM),
            .noto_medium_xl = createTextFormat(dw, noto, 20.0, .MEDIUM),
            .noto_medium_2xl = createTextFormat(dw, noto, 24.0, .MEDIUM),
            .noto_medium_3xl = createTextFormat(dw, noto, 30.0, .MEDIUM),
            .noto_medium_4xl = createTextFormat(dw, noto, 36.0, .MEDIUM),
            .noto_medium_5xl = createTextFormat(dw, noto, 48.0, .MEDIUM),
            .noto_medium_6xl = createTextFormat(dw, noto, 60.0, .MEDIUM),
            .noto_medium_7xl = createTextFormat(dw, noto, 72.0, .MEDIUM),
            .noto_medium_8xl = createTextFormat(dw, noto, 96.0, .MEDIUM),
            .noto_medium_9xl = createTextFormat(dw, noto, 128.0, .MEDIUM),
            .noto_bold_xs = createTextFormat(dw, noto, 12.0, .BOLD),
            .noto_bold_sm = createTextFormat(dw, noto, 14.0, .BOLD),
            .noto_bold_base = createTextFormat(dw, noto, 16.0, .BOLD),
            .noto_bold_lg = createTextFormat(dw, noto, 18.0, .BOLD),
            .noto_bold_xl = createTextFormat(dw, noto, 20.0, .BOLD),
            .noto_bold_2xl = createTextFormat(dw, noto, 24.0, .BOLD),
            .noto_bold_3xl = createTextFormat(dw, noto, 30.0, .BOLD),
            .noto_bold_4xl = createTextFormat(dw, noto, 36.0, .BOLD),
            .noto_bold_5xl = createTextFormat(dw, noto, 48.0, .BOLD),
            .noto_bold_6xl = createTextFormat(dw, noto, 60.0, .BOLD),
            .noto_bold_7xl = createTextFormat(dw, noto, 72.0, .BOLD),
            .noto_bold_8xl = createTextFormat(dw, noto, 96.0, .BOLD),
            .noto_bold_9xl = createTextFormat(dw, noto, 128.0, .BOLD),
        };
        ctx.brushes = BrushManager.init(allocator, rt);
        return ctx;
    }

    pub fn getTextFormat(this: *const DrawingContext, font: ui.style.Font) ?*dwrite.ITextFormat {
        return switch (font.weight) {
            .Normal => switch (font.size) {
                .XS => this.noto_normal_xs,
                .SM => this.noto_normal_sm,
                .Base => this.noto_normal_base,
                .LG => this.noto_normal_lg,
                .XL => this.noto_normal_xl,
                .XL2 => this.noto_normal_2xl,
                .XL3 => this.noto_normal_3xl,
                .XL4 => this.noto_normal_4xl,
                .XL5 => this.noto_normal_5xl,
                .XL6 => this.noto_normal_6xl,
                .XL7 => this.noto_normal_7xl,
                .XL8 => this.noto_normal_8xl,
                .XL9 => this.noto_normal_9xl,
            },
            .Medium => switch (font.size) {
                .XS => this.noto_medium_xs,
                .SM => this.noto_medium_sm,
                .Base => this.noto_medium_base,
                .LG => this.noto_medium_lg,
                .XL => this.noto_medium_xl,
                .XL2 => this.noto_medium_2xl,
                .XL3 => this.noto_medium_3xl,
                .XL4 => this.noto_medium_4xl,
                .XL5 => this.noto_medium_5xl,
                .XL6 => this.noto_medium_6xl,
                .XL7 => this.noto_medium_7xl,
                .XL8 => this.noto_medium_8xl,
                .XL9 => this.noto_medium_9xl,
            },
            .Bold => switch (font.size) {
                .XS => this.noto_bold_xs,
                .SM => this.noto_bold_sm,
                .Base => this.noto_bold_base,
                .LG => this.noto_bold_lg,
                .XL => this.noto_bold_xl,
                .XL2 => this.noto_bold_2xl,
                .XL3 => this.noto_bold_3xl,
                .XL4 => this.noto_bold_4xl,
                .XL5 => this.noto_bold_5xl,
                .XL6 => this.noto_bold_6xl,
                .XL7 => this.noto_bold_7xl,
                .XL8 => this.noto_bold_8xl,
                .XL9 => this.noto_bold_9xl,
            },
        };
    }

    pub fn deinit(this: *DrawingContext) void {
        _ = this.brushes.deinit();
        _ = this.noto_normal_xs.Release();
        _ = this.noto_normal_sm.Release();
        _ = this.noto_normal_base.Release();
        _ = this.noto_normal_lg.Release();
        _ = this.noto_normal_xl.Release();
        _ = this.noto_normal_2xl.Release();
        _ = this.noto_normal_3xl.Release();
        _ = this.noto_normal_4xl.Release();
        _ = this.noto_normal_5xl.Release();
        _ = this.noto_normal_6xl.Release();
        _ = this.noto_normal_7xl.Release();
        _ = this.noto_normal_8xl.Release();
        _ = this.noto_normal_9xl.Release();
        _ = this.noto_medium_xs.Release();
        _ = this.noto_medium_sm.Release();
        _ = this.noto_medium_base.Release();
        _ = this.noto_medium_lg.Release();
        _ = this.noto_medium_xl.Release();
        _ = this.noto_medium_2xl.Release();
        _ = this.noto_medium_3xl.Release();
        _ = this.noto_medium_4xl.Release();
        _ = this.noto_medium_5xl.Release();
        _ = this.noto_medium_6xl.Release();
        _ = this.noto_medium_7xl.Release();
        _ = this.noto_medium_8xl.Release();
        _ = this.noto_medium_9xl.Release();
        _ = this.noto_bold_xs.Release();
        _ = this.noto_bold_sm.Release();
        _ = this.noto_bold_base.Release();
        _ = this.noto_bold_lg.Release();
        _ = this.noto_bold_xl.Release();
        _ = this.noto_bold_2xl.Release();
        _ = this.noto_bold_3xl.Release();
        _ = this.noto_bold_4xl.Release();
        _ = this.noto_bold_5xl.Release();
        _ = this.noto_bold_6xl.Release();
        _ = this.noto_bold_7xl.Release();
        _ = this.noto_bold_8xl.Release();
        _ = this.noto_bold_9xl.Release();
        _ = this.r.Release();
    }
};

fn createBrush(render_target: *d2d1.IHwndRenderTarget, comptime hex: []const u8) *d2d1.ISolidColorBrush {
    var brush: *d2d1.ISolidColorBrush = undefined;
    const color = comptime hexToColor(hex);
    w32.vhr(render_target.CreateSolidColorBrush(&color, null, @ptrCast(&brush)));
    return brush;
}

fn hexToColor(hex: []const u8) d2d1.COLOR_F {
    const h = if (hex[0] == '#') hex[1..] else hex;
    const r = @as(f32, @floatFromInt(std.fmt.parseInt(u8, h[0..2], 16) catch 0)) / 255.0;
    const g = @as(f32, @floatFromInt(std.fmt.parseInt(u8, h[2..4], 16) catch 0)) / 255.0;
    const b = @as(f32, @floatFromInt(std.fmt.parseInt(u8, h[4..6], 16) catch 0)) / 255.0;
    return d2d1.COLOR_F{ .r = r, .g = g, .b = b, .a = 1.0 };
}

fn createTextFormat(dwrite_factory: *dwrite.IFactory, font: [:0]const u16, size: f32, weight: dwrite.FONT_WEIGHT) *dwrite.ITextFormat {
    var text_format: *dwrite.ITextFormat = undefined;
    w32.vhr(dwrite_factory.CreateTextFormat(
        font,
        null,
        weight,
        .NORMAL,
        .NORMAL,
        size,
        L("en-us"),
        @ptrCast(&text_format),
    ));
    return text_format;
}
