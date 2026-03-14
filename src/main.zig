const std = @import("std");
const w32 = @import("win32/win32.zig");
const d3d11 = @import("win32/d3d11.zig");
const dxgi = @import("win32/dxgi.zig");
const d2d1 = @import("win32/d2d1.zig");
const wic = @import("win32/wincodec.zig");
const dwrite = @import("win32/dwrite.zig");
const Style = @import("ui/style.zig").Style;
const Widget = @import("ui/widget.zig").Widget;
const ui = @import("ui.zig");
const drawing = @import("drawing.zig");

pub const std_options = std.Options{
    .log_level = .info,
};

export const D3D12SDKVersion: u32 = 614;
export const D3D12SDKPath: [*:0]const u8 = ".\\d3d12\\";

const window_name = "app";

const vhr = w32.vhr;
// var random_state = std.Random.DefaultPrng.init(0);
// const random = random_state.random();

pub fn main() !void {
    _ = w32.SetProcessDPIAware();

    _ = w32.CoInitializeEx(null, w32.COINIT_MULTITHREADED);
    defer w32.CoUninitialize();

    var _gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = _gpa.deinit();
    const gpa = _gpa.allocator();

    var app = try StaticContext.init();
    defer app.deinit();

    while (true) {
        var message = std.mem.zeroes(w32.MSG);
        if (w32.PeekMessageA(&message, null, 0, 0, w32.PM_REMOVE) == .TRUE) {
            _ = w32.TranslateMessage(&message);
            _ = w32.DispatchMessageA(&message);
            if (message.message == w32.WM_QUIT) break;
        }

        var _arena = std.heap.ArenaAllocator.init(gpa);
        const arena = _arena.allocator();
        if (app.update())
            app.draw(arena) catch @panic("adslfdsflkjadslkfjkj");

        _ = _arena.deinit();
    }
}

// stuff that has static lifetime gets thrown in here
const StaticContext = struct {
    hwnd: w32.HWND,

    wic_factory: *wic.IImagingFactory2,
    dwrite_factory: *dwrite.IFactory,

    d2d: struct {
        factory: *d2d1.IFactory6,
        device: *d2d1.IDevice5,
        device_context: *d2d1.IDeviceContext5,
        drawing_context: drawing.DrawingContext,
    },

    fn init() !StaticContext {
        const width = 800;
        const height = 600;
        const hwnd = create_window(width, height);

        var wic_factory: *wic.IImagingFactory2 = undefined;
        vhr(w32.CoCreateInstance(
            &wic.CLSID_ImagingFactory2,
            null,
            w32.CLSCTX_INPROC_SERVER,
            &wic.IImagingFactory2.IID,
            @ptrCast(&wic_factory),
        ));

        var dwrite_factory: *dwrite.IFactory = undefined;
        vhr(dwrite.CreateFactory(
            .SHARED,
            &dwrite.IFactory.IID,
            @ptrCast(&dwrite_factory),
        ));

        var d2d_factory: *d2d1.IFactory6 = undefined;
        vhr(d2d1.CreateFactory(
            .SINGLE_THREADED,
            &d2d1.IFactory6.IID,
            &.{ .debugLevel = .NONE },
            @ptrCast(&d2d_factory),
        ));

        const d2d_device, const d2d_device_context, const d2d_hwnd_target = blk: {
            var device11: *d3d11.IDevice = undefined;
            vhr(d3d11.CreateDevice(
                null,
                .WARP,
                null,
                .{ .DEBUG = false, .BGRA_SUPPORT = true },
                &.{.@"11_1"},
                1,
                d3d11.SDK_VERSION,
                @ptrCast(&device11),
                null,
                null,
            ));
            defer _ = device11.Release();

            var device11_1: *d3d11.IDevice1 = undefined;
            vhr(device11.QueryInterface(&d3d11.IDevice1.IID, @ptrCast(&device11_1)));
            defer _ = device11_1.Release();

            var dxgi_device: *dxgi.IDevice = undefined;
            vhr(device11_1.QueryInterface(&dxgi.IDevice.IID, @ptrCast(&dxgi_device)));
            defer _ = dxgi_device.Release();

            var d2d_device: *d2d1.IDevice5 = undefined;
            vhr(d2d_factory.CreateDevice5(dxgi_device, @ptrCast(&d2d_device)));

            var d2d_device_context: *d2d1.IDeviceContext5 = undefined;
            vhr(d2d_device.CreateDeviceContext5(.{}, @ptrCast(&d2d_device_context)));

            const render_target_props = d2d1.RENDER_TARGET_PROPERTIES{
                .type = .DEFAULT,
                .pixelFormat = .{ .format = .UNKNOWN, .alphaMode = .UNKNOWN },
                .dpiX = 0.0,
                .dpiY = 0.0,
                .usage = .{},
                .minLevel = .DEFAULT,
            };
            const hwnd_props = d2d1.HWND_RENDER_TARGET_PROPERTIES{
                .hwnd = hwnd,
                .pixelSize = .{ .width = @intCast(width), .height = @intCast(height) },
                .presentOptions = .{},
            };
            var d2d_hwnd_target: *d2d1.IHwndRenderTarget = undefined;
            vhr(d2d_factory.CreateHwndRenderTarget(&render_target_props, &hwnd_props, @ptrCast(&d2d_hwnd_target)));

            break :blk .{ d2d_device, d2d_device_context, d2d_hwnd_target };
        };

        const drawing_context = drawing.DrawingContext.init(dwrite_factory, d2d_hwnd_target);

        return .{
            .hwnd = hwnd,
            .wic_factory = wic_factory,
            .dwrite_factory = dwrite_factory,
            .d2d = .{
                .factory = d2d_factory,
                .device = d2d_device,
                .device_context = d2d_device_context,
                .drawing_context = drawing_context,
            },
        };
    }

    fn deinit(a: *StaticContext) void {
        _ = a.d2d.drawing_context.deinit();
        _ = a.d2d.device_context.Release();
        _ = a.d2d.device.Release();
        _ = a.d2d.factory.Release();
        _ = a.dwrite_factory.Release();
        _ = a.wic_factory.Release();

        a.* = undefined;
    }

    fn update(_: *StaticContext) bool {
        // switch (game.gpu_context.handle_window_resize()) {
        //     .minimized => {
        //         w32.Sleep(10);
        //         return false;
        //     },
        //     .resized => {},
        //     .unchanged => {},
        // }

        // _, const delta_time = update_frame_stats(game.gpu_context.window, window_name);

        return true;
    }

    fn draw(app: *StaticContext, allocator: std.mem.Allocator) !void {
        const ctx = app.d2d.drawing_context;
        const r = ctx.r;
        const size = r.GetSize();
        const w = size.width;
        const h = size.height;

        r.BeginDraw();
        defer vhr(r.EndDraw(null, null));

        r.FillRectangle(&d2d1.RECT_F{ .left = 0.0, .top = 0.0, .right = w, .bottom = h }, @ptrCast(ctx.slate900));

        const vstack = ui.VStack{ .style = .{ .background_color = ctx.slate800 } };
        const vstackRect = d2d1.RECT_F{ .left = w * 3 / 10, .top = h * 2 / 5, .right = w * 7 / 10, .bottom = h * 3 / 5 };
        vstack.render(&ctx, &vstackRect);

        const text = ui.Text{ .text = "Top text\nなんでやねん！", .style = .{
            .text_color = ctx.slate100,
            .font = .{ .size = .XL },
        } };
        text.render(allocator, &ctx, &vstackRect);
    }
};

fn process_window_message(
    window: w32.HWND,
    message: w32.UINT,
    wparam: w32.WPARAM,
    lparam: w32.LPARAM,
) callconv(w32.WINAPI) w32.LRESULT {
    switch (message) {
        w32.WM_KEYDOWN => {
            if (wparam == w32.VK_ESCAPE) {
                w32.PostQuitMessage(0);
                return 0;
            }
        },
        w32.WM_GETMINMAXINFO => {
            var info: *w32.MINMAXINFO = @ptrFromInt(@as(usize, @intCast(lparam)));
            info.ptMinTrackSize.x = 400;
            info.ptMinTrackSize.y = 400;
            return 0;
        },
        w32.WM_DESTROY => {
            w32.PostQuitMessage(0);
            return 0;
        },
        else => {},
    }
    return w32.DefWindowProcA(window, message, wparam, lparam);
}

fn create_window(width: i32, height: i32) w32.HWND {
    const winclass = w32.WNDCLASSEXA{
        .style = 0,
        .lpfnWndProc = process_window_message,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = @ptrCast(w32.GetModuleHandleA(null)),
        .hIcon = null,
        .hCursor = w32.LoadCursorA(null, @ptrFromInt(32512)),
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = window_name,
        .hIconSm = null,
    };
    _ = w32.RegisterClassExA(&winclass);

    const hwnd = w32.CreateWindowExA(
        0,
        window_name,
        window_name,
        w32.WS_OVERLAPPEDWINDOW,
        w32.CW_USEDEFAULT,
        w32.CW_USEDEFAULT,
        width,
        height,
        null,
        null,
        winclass.hInstance,
        null,
    ).?;

    _ = w32.ShowWindow(hwnd, w32.SW_SHOWDEFAULT);

    return hwnd;
}

fn update_frame_stats(window: w32.HWND, name: [:0]const u8) struct { f64, f32 } {
    const state = struct {
        var timer: std.time.Timer = undefined;
        var previous_time_ns: u64 = 0;
        var header_refresh_time_ns: u64 = 0;
        var frame_count: u64 = ~@as(u64, 0);
    };

    if (state.frame_count == ~@as(u64, 0)) {
        state.timer = std.time.Timer.start() catch unreachable;
        state.previous_time_ns = 0;
        state.header_refresh_time_ns = 0;
        state.frame_count = 0;
    }

    const now_ns = state.timer.read();
    const time = @as(f64, @floatFromInt(now_ns)) / std.time.ns_per_s;
    const delta_time = @as(f32, @floatFromInt(now_ns - state.previous_time_ns)) / std.time.ns_per_s;
    state.previous_time_ns = now_ns;

    if ((now_ns - state.header_refresh_time_ns) >= std.time.ns_per_s) {
        const t = @as(f64, @floatFromInt(now_ns - state.header_refresh_time_ns)) / std.time.ns_per_s;
        const fps = @as(f64, @floatFromInt(state.frame_count)) / t;
        const ms = (1.0 / fps) * 1000.0;

        var buffer = [_]u8{0} ** 128;
        const buffer_slice = buffer[0 .. buffer.len - 1];
        const header = std.fmt.bufPrint(
            buffer_slice,
            "[{d:.1} fps  {d:.3} ms] {s}",
            .{ fps, ms, name },
        ) catch buffer_slice;

        _ = w32.SetWindowTextA(window, @ptrCast(header.ptr));

        state.header_refresh_time_ns = now_ns;
        state.frame_count = 0;
    }
    state.frame_count += 1;

    return .{ time, delta_time };
}

fn is_key_down(vkey: c_int) bool {
    return (@as(w32.USHORT, @bitCast(w32.GetAsyncKeyState(vkey))) & 0x8000) != 0;
}
