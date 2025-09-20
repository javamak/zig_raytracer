const std = @import("std");

const entities = @import("entities.zig");
const primitives = @import("primitives.zig");
const engine = @import("render_engine.zig");
const zigTime = std.time;
const testing = std.testing;

pub fn main() !void {
    const sphere1 = primitives.Sphere{ .center = entities.Vector{ .x = 0, .y = 10000.5, .z = 1.0 }, .radius = 10000.0, .material = entities.Material{
        .chequered = true,
        .color = entities.Color{ .r = 66, .g = 5, .b = 0 },
        .color1 = entities.Color{ .r = 230, .g = 184, .b = 125 },
        .ambient = 0.2,
        .reflection = 0.2,
    } };
    const sphere2 = primitives.Sphere{ .center = entities.Vector{ .x = 0.75, .y = -0.1, .z = 2.25 }, .radius = 0.3, .material = entities.Material{
        .color = entities.Color{ .r = 0, .g = 0, .b = 255 },
    } };

    const sphere3 = primitives.Sphere{ .center = entities.Vector{ .x = -0.75, .y = -0.1, .z = 1.0 }, .radius = 0.3, .material = entities.Material{
        .color = entities.Color{ .r = 128, .g = 57, .b = 128 },
    } };

    const light1 = entities.Light{ .color = entities.Color{ .r = 255, .g = 255, .b = 255 }, .position = entities.Vector{ .x = 1.5, .y = -0.5, .z = -10.0 } };
    const light2 = entities.Light{ .color = entities.Color{ .r = 230, .g = 230, .b = 230 }, .position = entities.Vector{ .x = -0.5, .y = -10.5, .z = 0 } };
    const lights = [_]entities.Light{ light1, light2 };
    const objects = [_]primitives.Sphere{ sphere1, sphere2, sphere3 };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) @panic("Memory leak");
    }

    const scene = primitives.Scene{
        .height = 1080,
        .width = 1920,

        .camera = entities.Vector{ .x = 0, .y = -0.35, .z = -1 },
        .lights = &lights,
        .objects = &objects,
    };

    const time = zigTime.milliTimestamp();

    const image = try engine.render(&scene, allocator);
    defer {
        allocator.free(image.pixels);
        allocator.destroy(image);
    }

    const renderTime = zigTime.milliTimestamp() - time;
    std.debug.print("Render completed in {}\n", .{renderTime});
    try writeToFile(image);
    std.debug.print("File write completed in {}\n", .{zigTime.milliTimestamp() - time - renderTime});

    // std.debug.print("{any}", .{image});
}

const bufPrint = std.fmt.bufPrint;

pub fn writeToFile(image: *entities.Image) !void {
    const file = try std.fs.cwd().createFile("one.ppm", .{ .truncate = true });
    defer file.close();

    var b: [1024]u8 = undefined;

    var w = file.writer(&b);
    var writer = &w.interface;

    // Write PPM header

    try writer.print("P3 {d} {d}\n255\n", .{ image.width, image.height });
    for (image.pixels) |color| {
        try writer.print("{d} {d} {d} ", .{ toByte(color.r), toByte(color.g), toByte(color.b) });
    }
    try writer.flush();
}

fn toByte(x: f32) u8 {
    return @intFromFloat(std.math.round(@max(@min(x * 255, 255), 0)));
}

test "test toByte" {
    try testing.expectEqual(128, toByte(0.5));
    try testing.expectEqual(255, toByte(255.0));
    try testing.expectEqual(255, toByte(1.0));
    try testing.expectEqual(255, toByte(500.0));
}
