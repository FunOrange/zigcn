const std = @import("std");
const w32 = @import("win32/win32.zig");
const d3d11 = @import("win32/d3d11.zig");
const d3d12 = @import("win32/d3d12.zig");
const d3d12d = @import("win32/d3d12sdklayers.zig");
const dxgi = @import("win32/dxgi.zig");
const d2d1 = @import("win32/d2d1.zig");
const wic = @import("win32/wincodec.zig");
const dwrite = @import("win32/dwrite.zig");
const cpu_gpu = @cImport(@cInclude("cpu_gpu_shared.h"));
const gen_level = @import("gen_level.zig");
const gen_mesh = @import("gen_mesh.zig");

pub const std_options = std.Options{
    .log_level = .info,
};

// IDEAS:
// Level with rotating planets
// Level with neurons
// Level with PCB paths
// Level with logic gates

export const D3D12SDKVersion: u32 = 614;
export const D3D12SDKPath: [*:0]const u8 = ".\\d3d12\\";

const window_name = "zig-d3d12-starter";

const GpuContext = @import("GpuContext.zig");
const vhr = GpuContext.vhr;
const window_clear_color: [4]f32 = .{ 1, 1, 1, 0 };
const ds_target_format: dxgi.FORMAT = .D32_FLOAT;
var random_state = std.Random.DefaultPrng.init(0);
const random = random_state.random();

const pso_color = 0;
const pso_shadow = 1;
const pso_background = 2;
const pso_num = 3;

pub fn main() !void {
    _ = w32.SetProcessDPIAware();

    _ = w32.CoInitializeEx(null, w32.COINIT_MULTITHREADED);
    defer w32.CoUninitialize();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game = try GameState.init(allocator);
    defer game.deinit();

    while (true) {
        var message = std.mem.zeroes(w32.MSG);
        if (w32.PeekMessageA(&message, null, 0, 0, w32.PM_REMOVE) == .TRUE) {
            _ = w32.TranslateMessage(&message);
            _ = w32.DispatchMessageA(&message);
            if (message.message == w32.WM_QUIT) break;
        }

        if (game.update())
            game.draw();
    }
}

const GameState = struct {
    allocator: std.mem.Allocator,

    gpu_context: GpuContext,

    vertex_buffer: *d3d12.IResource,
    frame_state_buffer: *d3d12.IResource,

    pso: [pso_num]*d3d12.IPipelineState,
    pso_rs: *d3d12.IRootSignature,

    wic_factory: *wic.IImagingFactory2,
    dwrite_factory: *dwrite.IFactory,

    d2d: struct {
        factory: *d2d1.IFactory6,
        device: *d2d1.IDevice5,
        device_context: *d2d1.IDeviceContext5,
        render_target: *d2d1.IHwndRenderTarget,
    },

    meshes: std.ArrayList(gen_mesh.Mesh),

    player_is_dead: f32 = 0.0,
    player_to_next_level: f32 = 0.0,

    current_level_name: gen_level.LevelName,
    current_level: gen_level.LevelState,

    fn init(allocator: std.mem.Allocator) !GameState {
        var gpu_context = GpuContext.init(
            create_window(
                @divTrunc(w32.GetSystemMetrics(w32.SM_CXSCREEN), 2),
                @divTrunc(w32.GetSystemMetrics(w32.SM_CYSCREEN), 2),
            ),
            .{
                .color_target_clear_color = window_clear_color,
                .ds_target_format = .D32_FLOAT,
            },
        );

        const pso, const pso_rs = create_pso(gpu_context.device);

        var frame_state_buffer: *d3d12.IResource = undefined;
        vhr(gpu_context.device.CreateCommittedResource3(
            &.{ .Type = .DEFAULT },
            .ALLOW_ALL_BUFFERS_AND_TEXTURES,
            &.{
                .Dimension = .BUFFER,
                .Width = @sizeOf(cpu_gpu.FrameState),
                .Layout = .ROW_MAJOR,
            },
            .UNDEFINED,
            null,
            null,
            0,
            null,
            &d3d12.IResource.IID,
            @ptrCast(&frame_state_buffer),
        ));

        gpu_context.device.CreateConstantBufferView(
            &.{
                .BufferLocation = frame_state_buffer.GetGPUVirtualAddress(),
                .SizeInBytes = @sizeOf(cpu_gpu.FrameState),
            },
            .{ .ptr = gpu_context.shader_dheap_start_cpu.ptr +
                @as(u32, @intCast(cpu_gpu.rdh_frame_state_buffer)) *
                    gpu_context.shader_dheap_descriptor_size },
        );

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
            if (GpuContext.d3d12_debug) &.{ .debugLevel = .INFORMATION } else &.{ .debugLevel = .NONE },
            @ptrCast(&d2d_factory),
        ));

        const d2d_device, const d2d_device_context, const render_target = blk: {
            var device11: *d3d11.IDevice = undefined;
            vhr(d3d11.CreateDevice(
                null,
                .WARP,
                null,
                .{ .DEBUG = GpuContext.d3d12_debug, .BGRA_SUPPORT = true },
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
                .hwnd = gpu_context.window,
                .pixelSize = .{ .width = gpu_context.window_width, .height = gpu_context.window_height },
                .presentOptions = .{},
            };
            var render_target: *d2d1.IHwndRenderTarget = undefined;
            vhr(d2d_factory.CreateHwndRenderTarget(&render_target_props, &hwnd_props, @ptrCast(&render_target)));

            break :blk .{ d2d_device, d2d_device_context, render_target };
        };

        const meshes, const vertex_buffer = try gen_mesh.define_and_upload_meshes(allocator, &gpu_context, d2d_factory);

        const current_level_name = .rotating_arm_and_gear;
        const current_level = try gen_level.define_and_upload_level(
            allocator,
            &gpu_context,
            current_level_name,
        );

        return .{
            .allocator = allocator,
            .gpu_context = gpu_context,
            .vertex_buffer = vertex_buffer,
            .frame_state_buffer = frame_state_buffer,
            .pso = pso,
            .pso_rs = pso_rs,
            .meshes = meshes,
            .wic_factory = wic_factory,
            .dwrite_factory = dwrite_factory,
            .d2d = .{
                .factory = d2d_factory,
                .device = d2d_device,
                .device_context = d2d_device_context,
                .render_target = render_target,
            },
            .current_level = current_level,
            .current_level_name = current_level_name,
        };
    }

    fn deinit(game: *GameState) void {
        game.gpu_context.finish_gpu_commands();

        for (game.meshes.items) |mesh| {
            if (mesh.geometry) |geometry| _ = geometry.Release();
        }
        game.meshes.deinit();
        game.current_level.deinit();

        _ = game.d2d.device_context.Release();
        _ = game.d2d.device.Release();
        _ = game.d2d.factory.Release();
        _ = game.dwrite_factory.Release();
        _ = game.wic_factory.Release();

        for (game.pso) |pso| _ = pso.Release();
        _ = game.pso_rs.Release();
        _ = game.vertex_buffer.Release();
        _ = game.frame_state_buffer.Release();

        game.gpu_context.deinit();

        game.* = undefined;
    }

    fn update(game: *GameState) bool {
        switch (game.gpu_context.handle_window_resize()) {
            .minimized => {
                w32.Sleep(10);
                return false;
            },
            .resized => {},
            .unchanged => {},
        }

        // _, const delta_time = update_frame_stats(game.gpu_context.window, window_name);
        // const window_width: f32 = @floatFromInt(game.gpu_context.window_width);
        // const window_height: f32 = @floatFromInt(game.gpu_context.window_height);

        return true;
    }

    fn draw(game: *GameState) void {
        const ctx = game.d2d.render_target;

        var brush: *d2d1.ISolidColorBrush = undefined;
        vhr(ctx.CreateSolidColorBrush(
            &.{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 },
            null,
            @ptrCast(&brush),
        ));
        defer _ = brush.Release();

        ctx.BeginDraw();
        ctx.DrawRectangle(
            &d2d1.RECT_F{ .left = 0.0, .top = 0.0, .right = 100.0, .bottom = 0.0 },
            @ptrCast(brush),
            1,
            null,
        );
        vhr(ctx.EndDraw(null, null));

        // const level = &game.current_level;
        // const gc = &game.gpu_context;

        // gc.begin_command_list();

        // gc.command_list.Barrier(1, &.{
        //     .{
        //         .Type = .BUFFER,
        //         .NumBarriers = 2,
        //         .u = .{
        //             .pBufferBarriers = &.{
        //                 .{
        //                     .SyncBefore = .{},
        //                     .SyncAfter = .{ .COPY = true },
        //                     .AccessBefore = .{ .NO_ACCESS = true },
        //                     .AccessAfter = .{ .COPY_DEST = true },
        //                     .pResource = game.frame_state_buffer,
        //                 },
        //                 .{
        //                     .SyncBefore = .{},
        //                     .SyncAfter = .{ .COPY = true },
        //                     .AccessBefore = .{ .NO_ACCESS = true },
        //                     .AccessAfter = .{ .COPY_DEST = true },
        //                     .pResource = level.objects_gpu,
        //                 },
        //             },
        //         },
        //     },
        // });

        // {
        //     const proj = proj: {
        //         const width: f32 = @floatFromInt(gc.window_width);
        //         const height: f32 = @floatFromInt(gc.window_height);
        //         const aspect = width / height;

        //         break :proj orthographic_off_center(
        //             -0.5 * gen_level.map_size_y * aspect,
        //             0.5 * gen_level.map_size_y * aspect,
        //             0.0,
        //             gen_level.map_size_y,
        //             0.0,
        //             1.0,
        //         );
        //     };

        //     const upload_mem, const buffer, const offset = gc.allocate_upload_buffer_region(cpu_gpu.FrameState, 1);

        //     upload_mem[0] = .{
        //         .proj = transpose(proj),
        //     };

        //     gc.command_list.CopyBufferRegion(
        //         game.frame_state_buffer,
        //         0,
        //         buffer,
        //         offset,
        //         upload_mem.len * @sizeOf(@TypeOf(upload_mem[0])),
        //     );
        // }

        // {
        //     const upload_mem, const buffer, const offset = gc.allocate_upload_buffer_region(
        //         cpu_gpu.Object,
        //         @intCast(level.objects_cpu.items.len),
        //     );

        //     for (level.objects_cpu.items, 0..) |object, i| upload_mem[i] = object;

        //     gc.command_list.CopyBufferRegion(
        //         level.objects_gpu,
        //         0,
        //         buffer,
        //         offset,
        //         upload_mem.len * @sizeOf(@TypeOf(upload_mem[0])),
        //     );
        // }

        // gc.command_list.Barrier(1, &.{
        //     .{
        //         .Type = .BUFFER,
        //         .NumBarriers = 2,
        //         .u = .{
        //             .pBufferBarriers = &.{
        //                 .{
        //                     .SyncBefore = .{ .COPY = true },
        //                     .SyncAfter = .{ .DRAW = true },
        //                     .AccessBefore = .{ .COPY_DEST = true },
        //                     .AccessAfter = .{ .CONSTANT_BUFFER = true },
        //                     .pResource = game.frame_state_buffer,
        //                 },
        //                 .{
        //                     .SyncBefore = .{ .COPY = true },
        //                     .SyncAfter = .{ .DRAW = true },
        //                     .AccessBefore = .{ .COPY_DEST = true },
        //                     .AccessAfter = .{ .SHADER_RESOURCE = true },
        //                     .pResource = level.objects_gpu,
        //                 },
        //             },
        //         },
        //     },
        // });

        // gc.command_list.OMSetRenderTargets(1, &.{gc.display_target_descriptor()}, .TRUE, &gc.dsv_dheap_start);
        // {
        //     const c = d2d1.COLOR_F.init(.RoyalBlue, 1.0);
        //     gc.command_list.ClearRenderTargetView(gc.display_target_descriptor(), &.{ c.r, c.g, c.b, c.a }, 0, null);
        // }
        // gc.command_list.ClearDepthStencilView(gc.dsv_dheap_start, .{ .DEPTH = true }, 1.0, 0, 0, null);

        // gc.command_list.IASetPrimitiveTopology(.TRIANGLELIST);
        // gc.command_list.SetGraphicsRootSignature(game.pso_rs);

        // // Draw background.
        // {
        //     const mesh = &game.meshes.items[gen_mesh.Mesh.fullscreen_rect];

        //     gc.command_list.SetPipelineState(game.pso[pso_background]);
        //     gc.command_list.SetGraphicsRoot32BitConstants(
        //         0,
        //         3,
        //         &[_]u32{ mesh.first_vertex, 0, 0 },
        //         0,
        //     );
        //     gc.command_list.DrawInstanced(mesh.num_vertices, 1, 0, 0);
        // }

        // const objects = level.objects_cpu.items[0..];

        // gc.command_list.SetPipelineState(game.pso[pso_color]);

        // // Draw objects that don't cast shadows.
        // for (objects, 0..) |object, object_id| {
        //     if (object.flags & cpu_gpu.obj_flag_is_dead != 0) continue;
        //     if (object.flags & cpu_gpu.obj_flag_no_shadow == 0) continue;

        //     for (0..object.mesh_indices.len) |submesh| {
        //         if (object.mesh_indices[submesh] == gen_mesh.Mesh.invalid) continue;

        //         const mesh = &game.meshes.items[object.mesh_indices[submesh]];

        //         gc.command_list.SetGraphicsRoot32BitConstants(
        //             0,
        //             3,
        //             &[_]u32{ mesh.first_vertex, @intCast(object_id), @intCast(submesh) },
        //             0,
        //         );
        //         gc.command_list.DrawInstanced(mesh.num_vertices, 1, 0, 0);
        //     }
        // }

        // // Draw shadows.
        // gc.command_list.SetPipelineState(game.pso[pso_shadow]);

        // for (objects, 0..) |object, object_id| {
        //     if (object.flags & cpu_gpu.obj_flag_is_dead != 0) continue;
        //     if (object.flags & cpu_gpu.obj_flag_no_shadow != 0) continue;

        //     for (0..object.mesh_indices.len) |submesh| {
        //         if (object.mesh_indices[submesh] == gen_mesh.Mesh.invalid) continue;

        //         const mesh = &game.meshes.items[object.mesh_indices[submesh]];

        //         gc.command_list.SetGraphicsRoot32BitConstants(
        //             0,
        //             3,
        //             &[_]u32{ mesh.first_vertex, @intCast(object_id), @intCast(submesh) },
        //             0,
        //         );
        //         gc.command_list.DrawInstanced(mesh.num_vertices, 1, 0, 0);
        //     }
        // }

        // // Draw objects that do cast shadows.
        // gc.command_list.SetPipelineState(game.pso[pso_color]);

        // for (objects, 0..) |object, object_id| {
        //     if (object.flags & cpu_gpu.obj_flag_is_dead != 0) continue;
        //     if (object.flags & cpu_gpu.obj_flag_no_shadow != 0) continue;

        //     for (0..object.mesh_indices.len) |submesh| {
        //         if (object.mesh_indices[submesh] == gen_mesh.Mesh.invalid) continue;

        //         const mesh = &game.meshes.items[object.mesh_indices[submesh]];

        //         gc.command_list.SetGraphicsRoot32BitConstants(
        //             0,
        //             3,
        //             &[_]u32{ mesh.first_vertex, @intCast(object_id), @intCast(submesh) },
        //             0,
        //         );
        //         gc.command_list.DrawInstanced(mesh.num_vertices, 1, 0, 0);
        //     }
        // }

        // gc.end_command_list();

        // gc.command_queue.ExecuteCommandLists(1, &.{@ptrCast(gc.command_list)});
        // gc.present_frame();
    }
};

fn create_pso(device: *GpuContext.IDevice) struct { [pso_num]*d3d12.IPipelineState, *d3d12.IRootSignature } {
    const s00_vs = @embedFile("cso/s00.vs.cso");
    const s00_ps = @embedFile("cso/s00.ps.cso");
    const s00_shadow_vs = @embedFile("cso/s00_shadow.vs.cso");
    const s00_shadow_ps = @embedFile("cso/s00_shadow.ps.cso");
    const s01_vs = @embedFile("cso/s01.vs.cso");
    const s01_ps = @embedFile("cso/s01.ps.cso");

    var pso_rs: *d3d12.IRootSignature = undefined;
    vhr(device.CreateRootSignature(
        0,
        s00_vs,
        s00_vs.len,
        &d3d12.IRootSignature.IID,
        @ptrCast(&pso_rs),
    ));

    var pso: [pso_num]*d3d12.IPipelineState = undefined;
    vhr(device.CreateGraphicsPipelineState(
        &.{
            .DepthStencilState = .{ .DepthEnable = .FALSE },
            .DSVFormat = ds_target_format,
            .RTVFormats = .{GpuContext.display_target_format} ++ .{.UNKNOWN} ** 7,
            .NumRenderTargets = 1,
            .BlendState = .{
                .RenderTarget = [_]d3d12.RENDER_TARGET_BLEND_DESC{.{
                    .RenderTargetWriteMask = 0x0f,
                    .BlendEnable = .TRUE,
                    .SrcBlend = .SRC_ALPHA,
                    .DestBlend = .INV_SRC_ALPHA,
                }} ++ [_]d3d12.RENDER_TARGET_BLEND_DESC{.{}} ** 7,
            },
            .PrimitiveTopologyType = .TRIANGLE,
            .VS = .{ .pShaderBytecode = s00_vs, .BytecodeLength = s00_vs.len },
            .PS = .{ .pShaderBytecode = s00_ps, .BytecodeLength = s00_ps.len },
            .SampleDesc = .{ .Count = GpuContext.display_target_num_samples },
        },
        &d3d12.IPipelineState.IID,
        @ptrCast(&pso[pso_color]),
    ));

    vhr(device.CreateGraphicsPipelineState(
        &.{
            .DepthStencilState = .{ .DepthEnable = .TRUE },
            .DSVFormat = ds_target_format,
            .RTVFormats = .{GpuContext.display_target_format} ++ .{.UNKNOWN} ** 7,
            .NumRenderTargets = 1,
            .BlendState = .{
                .RenderTarget = [_]d3d12.RENDER_TARGET_BLEND_DESC{.{
                    .RenderTargetWriteMask = 0x0f,
                    .BlendEnable = .TRUE,
                    .SrcBlend = .SRC_ALPHA,
                    .DestBlend = .INV_SRC_ALPHA,
                }} ++ [_]d3d12.RENDER_TARGET_BLEND_DESC{.{}} ** 7,
            },
            .PrimitiveTopologyType = .TRIANGLE,
            .VS = .{ .pShaderBytecode = s00_shadow_vs, .BytecodeLength = s00_shadow_vs.len },
            .PS = .{ .pShaderBytecode = s00_shadow_ps, .BytecodeLength = s00_shadow_ps.len },
            .SampleDesc = .{ .Count = GpuContext.display_target_num_samples },
        },
        &d3d12.IPipelineState.IID,
        @ptrCast(&pso[pso_shadow]),
    ));

    vhr(device.CreateGraphicsPipelineState(
        &.{
            .DepthStencilState = .{ .DepthEnable = .FALSE },
            .DSVFormat = ds_target_format,
            .RTVFormats = .{GpuContext.display_target_format} ++ .{.UNKNOWN} ** 7,
            .NumRenderTargets = 1,
            .BlendState = .{
                .RenderTarget = [_]d3d12.RENDER_TARGET_BLEND_DESC{.{
                    .RenderTargetWriteMask = 0x0f,
                }} ++ [_]d3d12.RENDER_TARGET_BLEND_DESC{.{}} ** 7,
            },
            .PrimitiveTopologyType = .TRIANGLE,
            .VS = .{ .pShaderBytecode = s01_vs, .BytecodeLength = s01_vs.len },
            .PS = .{ .pShaderBytecode = s01_ps, .BytecodeLength = s01_ps.len },
            .SampleDesc = .{ .Count = GpuContext.display_target_num_samples },
        },
        &d3d12.IPipelineState.IID,
        @ptrCast(&pso[pso_background]),
    ));

    return .{ pso, pso_rs };
}

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

    const window = w32.CreateWindowExA(
        if (@import("builtin").mode == .Debug) 0 else w32.WS_EX_TOPMOST,
        window_name,
        window_name,
        if (@import("builtin").mode == .Debug) w32.WS_OVERLAPPEDWINDOW else w32.WS_POPUP,
        w32.CW_USEDEFAULT,
        w32.CW_USEDEFAULT,
        width,
        height,
        null,
        null,
        winclass.hInstance,
        null,
    ).?;

    _ = w32.ShowWindow(window, w32.SW_SHOWMAXIMIZED);

    if (@import("builtin").mode != .Debug)
        _ = w32.ShowCursor(.FALSE);

    return window;
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

fn orthographic_off_center(l: f32, r: f32, t: f32, b: f32, n: f32, f: f32) [16]f32 {
    std.debug.assert(!std.math.approxEqAbs(f32, f, n, 0.001));

    const d = 1 / (f - n);
    return .{
        2 / (r - l),        0.0,                0.0,    0.0,
        0.0,                2 / (t - b),        0.0,    0.0,
        0.0,                0.0,                d,      0.0,
        -(r + l) / (r - l), -(t + b) / (t - b), -d * n, 1.0,
    };
}

fn transpose(m: [16]f32) [16]f32 {
    return .{
        m[0], m[4], m[8],  m[12],
        m[1], m[5], m[9],  m[13],
        m[2], m[6], m[10], m[14],
        m[3], m[7], m[11], m[15],
    };
}

fn is_key_down(vkey: c_int) bool {
    return (@as(w32.USHORT, @bitCast(w32.GetAsyncKeyState(vkey))) & 0x8000) != 0;
}
