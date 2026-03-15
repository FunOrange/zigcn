const std = @import("std");
const w32 = @import("win32/win32.zig");
const d2d1 = @import("win32/d2d1.zig");
const dwrite = @import("win32/dwrite.zig");
const ui = @import("ui.zig");
const data_structures = @import("data-structures.zig");

const L = std.unicode.utf8ToUtf16LeStringLiteral;

const BRUSH_CACHE_SIZE = 128;
const TEXT_FORMAT_CACHE_SIZE = 128;

const BrushCache = data_structures.StringLruCache(*d2d1.ISolidColorBrush, BRUSH_CACHE_SIZE);
const TextFormatCache = data_structures.AutoLruCache(ui.style.Font, *dwrite.ITextFormat, TEXT_FORMAT_CACHE_SIZE);

pub const DrawingContext = struct {
    r: *d2d1.IHwndRenderTarget,
    dw: *dwrite.IFactory,

    brushes: BrushManager,
    fonts: TextFormatManager,

    pub fn init(allocator: std.mem.Allocator, dw: *dwrite.IFactory, rt: *d2d1.IHwndRenderTarget) DrawingContext {
        return .{
            .r = rt,
            .dw = dw,
            .brushes = BrushManager.init(allocator, rt),
            .fonts = TextFormatManager.init(allocator, dw),
        };
    }

    pub fn deinit(this: *DrawingContext) void {
        this.brushes.deinit();
        this.fonts.deinit();
        _ = this.r.Release();
    }
};

const BrushManager = struct {
    cache: BrushCache,
    rt: *d2d1.IHwndRenderTarget,

    pub fn init(allocator: std.mem.Allocator, rt: *d2d1.IHwndRenderTarget) BrushManager {
        return .{
            .cache = BrushCache.init(allocator),
            .rt = rt,
        };
    }

    pub fn deinit(self: *BrushManager) void {
        var iter = self.cache.map.iterator();
        while (iter.next()) |entry| {
            _ = entry.value_ptr.value.Release();
        }
        self.cache.deinit();
    }

    pub fn get(self: *BrushManager, hex: []const u8) *d2d1.ISolidColorBrush {
        if (self.cache.get(hex)) |brush| {
            return brush;
        }

        const brush = createBrush(self.rt, hex);
        if (self.cache.put(hex, brush) catch unreachable) |evicted| {
            _ = evicted.Release();
        }
        return brush;
    }
};

const TextFormatManager = struct {
    cache: TextFormatCache,
    dw: *dwrite.IFactory,

    pub fn init(allocator: std.mem.Allocator, dw: *dwrite.IFactory) TextFormatManager {
        return .{
            .cache = TextFormatCache.init(allocator),
            .dw = dw,
        };
    }

    pub fn deinit(self: *TextFormatManager) void {
        var iter = self.cache.map.iterator();
        while (iter.next()) |entry| {
            _ = entry.value_ptr.value.Release();
        }
        self.cache.deinit();
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
};

fn createBrush(render_target: *d2d1.IHwndRenderTarget, hex: []const u8) *d2d1.ISolidColorBrush {
    var brush: *d2d1.ISolidColorBrush = undefined;
    const color = hexToColor(hex);
    w32.vhr(render_target.CreateSolidColorBrush(&color, null, @ptrCast(&brush)));
    return brush;
}

fn hexToColor(hex: []const u8) d2d1.COLOR_F {
    const h = if (hex.len > 0 and hex[0] == '#') hex[1..] else hex;
    const r = @as(f32, @floatFromInt(std.fmt.parseInt(u8, h[0..2], 16) catch 0)) / 255.0;
    const g = @as(f32, @floatFromInt(std.fmt.parseInt(u8, h[2..4], 16) catch 0)) / 255.0;
    const b = @as(f32, @floatFromInt(std.fmt.parseInt(u8, h[4..6], 16) catch 0)) / 255.0;
    return .{ .r = r, .g = g, .b = b, .a = 1.0 };
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
