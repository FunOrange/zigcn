const std = @import("std");
const w32 = @import("win32/win32.zig");
const d2d1 = @import("win32/d2d1.zig");
const dwrite = @import("win32/dwrite.zig");
const style = @import("ui/style.zig");

const L = std.unicode.utf8ToUtf16LeStringLiteral;

const noto = L("Noto Sans JP");

pub const DrawingContext = struct {
    r: *d2d1.IHwndRenderTarget,
    dw: *dwrite.IFactory,

    // brushes
    slate50: *d2d1.ISolidColorBrush,
    slate100: *d2d1.ISolidColorBrush,
    slate200: *d2d1.ISolidColorBrush,
    slate300: *d2d1.ISolidColorBrush,
    slate400: *d2d1.ISolidColorBrush,
    slate500: *d2d1.ISolidColorBrush,
    slate600: *d2d1.ISolidColorBrush,
    slate700: *d2d1.ISolidColorBrush,
    slate800: *d2d1.ISolidColorBrush,
    slate900: *d2d1.ISolidColorBrush,
    slate950: *d2d1.ISolidColorBrush,
    rose50: *d2d1.ISolidColorBrush,
    rose100: *d2d1.ISolidColorBrush,
    rose200: *d2d1.ISolidColorBrush,
    rose300: *d2d1.ISolidColorBrush,
    rose400: *d2d1.ISolidColorBrush,
    rose500: *d2d1.ISolidColorBrush,
    rose600: *d2d1.ISolidColorBrush,
    rose700: *d2d1.ISolidColorBrush,
    rose800: *d2d1.ISolidColorBrush,
    rose900: *d2d1.ISolidColorBrush,
    rose950: *d2d1.ISolidColorBrush,

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

    pub fn init(dw: *dwrite.IFactory, rt: *d2d1.IHwndRenderTarget) DrawingContext {
        return .{
            .r = rt,
            .dw = dw,
            .slate50 = createBrush(rt, "#f8fafc"),
            .slate100 = createBrush(rt, "#f1f5f9"),
            .slate200 = createBrush(rt, "#e2e8f0"),
            .slate300 = createBrush(rt, "#cbd5e1"),
            .slate400 = createBrush(rt, "#94a3b8"),
            .slate500 = createBrush(rt, "#64748b"),
            .slate600 = createBrush(rt, "#475569"),
            .slate700 = createBrush(rt, "#334155"),
            .slate800 = createBrush(rt, "#1e293b"),
            .slate900 = createBrush(rt, "#0f172a"),
            .slate950 = createBrush(rt, "#020617"),
            .rose50 = createBrush(rt, "#fff1f2"),
            .rose100 = createBrush(rt, "#ffe4e6"),
            .rose200 = createBrush(rt, "#fecdd3"),
            .rose300 = createBrush(rt, "#fda4af"),
            .rose400 = createBrush(rt, "#fb7185"),
            .rose500 = createBrush(rt, "#f43f5e"),
            .rose600 = createBrush(rt, "#e11d48"),
            .rose700 = createBrush(rt, "#be123c"),
            .rose800 = createBrush(rt, "#9f1239"),
            .rose900 = createBrush(rt, "#881337"),
            .rose950 = createBrush(rt, "#4c0519"),
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
    }

    pub fn getTextFormat(this: *const DrawingContext, font: style.Font) ?*dwrite.ITextFormat {
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
        _ = this.slate50.Release();
        _ = this.slate100.Release();
        _ = this.slate200.Release();
        _ = this.slate300.Release();
        _ = this.slate400.Release();
        _ = this.slate500.Release();
        _ = this.slate600.Release();
        _ = this.slate700.Release();
        _ = this.slate800.Release();
        _ = this.slate900.Release();
        _ = this.slate950.Release();
        _ = this.rose50.Release();
        _ = this.rose100.Release();
        _ = this.rose200.Release();
        _ = this.rose300.Release();
        _ = this.rose400.Release();
        _ = this.rose500.Release();
        _ = this.rose600.Release();
        _ = this.rose700.Release();
        _ = this.rose800.Release();
        _ = this.rose900.Release();
        _ = this.rose950.Release();
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
