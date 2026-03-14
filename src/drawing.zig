const std = @import("std");
const w32 = @import("win32/win32.zig");
const d2d1 = @import("win32/d2d1.zig");

pub const DrawingContext = struct {
    r: *d2d1.IHwndRenderTarget,

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

    pub fn init(r: *d2d1.IHwndRenderTarget) DrawingContext {
        return .{
            .r = r,
            .slate50 = createBrush(r, "#f8fafc"),
            .slate100 = createBrush(r, "#f1f5f9"),
            .slate200 = createBrush(r, "#e2e8f0"),
            .slate300 = createBrush(r, "#cbd5e1"),
            .slate400 = createBrush(r, "#94a3b8"),
            .slate500 = createBrush(r, "#64748b"),
            .slate600 = createBrush(r, "#475569"),
            .slate700 = createBrush(r, "#334155"),
            .slate800 = createBrush(r, "#1e293b"),
            .slate900 = createBrush(r, "#0f172a"),
            .slate950 = createBrush(r, "#020617"),
            .rose50 = createBrush(r, "#fff1f2"),
            .rose100 = createBrush(r, "#ffe4e6"),
            .rose200 = createBrush(r, "#fecdd3"),
            .rose300 = createBrush(r, "#fda4af"),
            .rose400 = createBrush(r, "#fb7185"),
            .rose500 = createBrush(r, "#f43f5e"),
            .rose600 = createBrush(r, "#e11d48"),
            .rose700 = createBrush(r, "#be123c"),
            .rose800 = createBrush(r, "#9f1239"),
            .rose900 = createBrush(r, "#881337"),
            .rose950 = createBrush(r, "#4c0519"),
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
