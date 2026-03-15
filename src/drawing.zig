const std = @import("std");
const w32 = @import("win32/win32.zig");
const d2d1 = @import("win32/d2d1.zig");
const dwrite = @import("win32/dwrite.zig");
const ui = @import("ui.zig");
const StringLruCache = @import("data-structures.zig").StringLruCache;
const AutoLruCache = @import("data-structures.zig").AutoLruCache;

const L = std.unicode.utf8ToUtf16LeStringLiteral;

pub const DrawingContext = struct {
    r: *d2d1.IHwndRenderTarget,
    dw: *dwrite.IFactory,

    // brushes
    brushes: BrushManager,
    fonts: TextFormatManager,

    pub fn init(allocator: std.mem.Allocator, dw: *dwrite.IFactory, rt: *d2d1.IHwndRenderTarget) DrawingContext {
        var ctx = DrawingContext{
            .r = rt,
            .dw = dw,
            .brushes = undefined,
            .fonts = undefined,
        };
        ctx.brushes = BrushManager.init(allocator, rt);
        ctx.fonts = TextFormatManager.init(allocator, dw);
        return ctx;
    }

    pub fn deinit(this: *DrawingContext) void {
        _ = this.brushes.deinit();
        _ = this.fonts.deinit();
        _ = this.r.Release();
    }
};

const BRUSH_CACHE_SIZE = 128;

const BrushManager = struct {
    cache: *StringLruCache(*d2d1.ISolidColorBrush, BRUSH_CACHE_SIZE),
    rt: *d2d1.IHwndRenderTarget,

    pub fn init(allocator: std.mem.Allocator, rt: *d2d1.IHwndRenderTarget) BrushManager {
        const cache = allocator.create(StringLruCache(*d2d1.ISolidColorBrush, BRUSH_CACHE_SIZE)) catch unreachable;
        cache.* = StringLruCache(*d2d1.ISolidColorBrush, BRUSH_CACHE_SIZE).init(allocator);
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

const TEXT_FORMAT_CACHE_SIZE = 128;

const TextFormatManager = struct {
    cache: *AutoLruCache(ui.style.Font, *dwrite.ITextFormat, TEXT_FORMAT_CACHE_SIZE),
    dw: *dwrite.IFactory,

    pub fn init(allocator: std.mem.Allocator, dw: *dwrite.IFactory) TextFormatManager {
        const cache = allocator.create(AutoLruCache(ui.style.Font, *dwrite.ITextFormat, TEXT_FORMAT_CACHE_SIZE)) catch unreachable;
        cache.* = AutoLruCache(ui.style.Font, *dwrite.ITextFormat, TEXT_FORMAT_CACHE_SIZE).init(allocator);
        return .{
            .cache = cache,
            .dw = dw,
        };
    }

    pub fn get(self: *TextFormatManager, key: ui.style.Font) *dwrite.ITextFormat {
        if (self.cache.get(key)) |text_format| {
            return text_format;
        }
        const text_format = createTextFormat(self.dw, key);
        if (self.cache.put(key, text_format) catch unreachable) |evicted| {
            _ = evicted.Release();
        }
        return text_format;
    }

    pub fn deinit(self: *TextFormatManager) void {
        var iter = self.cache.map.iterator();
        while (iter.next()) |entry| {
            const text_format = entry.value_ptr.value;
            _ = text_format.Release();
        }
        self.cache.deinit();
    }
};

fn createBrush(render_target: *d2d1.IHwndRenderTarget, hex: []const u8) *d2d1.ISolidColorBrush {
    var brush: *d2d1.ISolidColorBrush = undefined;
    const color = hexToColor(hex);
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

fn createTextFormat(dwrite_factory: *dwrite.IFactory, font: ui.style.Font) *dwrite.ITextFormat {
    const dwrite_font = switch (font.family) {
        .NotoSansJP => L("Noto Sans JP"),
        .SegoeUI => L("Segoe UI"),
    };
    const dwrite_weight: dwrite.FONT_WEIGHT = switch (font.weight) {
        .Normal => .NORMAL,
        .Medium => .MEDIUM,
        .Semibold => .SEMI_BOLD,
        .Bold => .BOLD,
    };
    const dwrite_size: f32 = switch (font.size) {
        .xs => 12.0,
        .sm => 14.0,
        .Base => 16.0,
        .lg => 18.0,
        .xl => 20.0,
        .xl2 => 24.0,
        .xl3 => 28.0,
        .xl4 => 32.0,
        .xl5 => 36.0,
        .xl6 => 40.0,
        .xl7 => 44.0,
        .xl8 => 48.0,
        .xl9 => 52.0,
    };

    var text_format: *dwrite.ITextFormat = undefined;
    w32.vhr(dwrite_factory.CreateTextFormat(
        dwrite_font,
        null,
        dwrite_weight,
        .NORMAL,
        .NORMAL,
        dwrite_size,
        L("en-us"),
        @ptrCast(&text_format),
    ));
    return text_format;
}
