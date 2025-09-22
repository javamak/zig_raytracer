const std = @import("std");

const entities = @import("entities.zig");
const primitives = @import("primitives.zig");
const engine = @import("render_engine.zig");
const zigTime = std.time;
const testing = std.testing;

pub fn main() !void {
    const scene = loadScene();
    const start = zigTime.milliTimestamp();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) @panic("Memory leak");
    }

    const renderStart = zigTime.milliTimestamp();

    const image = try engine.renderMultiThread(&scene, allocator);
    defer {
        allocator.free(image.pixels);
        allocator.destroy(image);
    }

    const renderTime = zigTime.milliTimestamp() - renderStart;
    const fileWriteStart = zigTime.milliTimestamp();
    try writeToFile(image);
    const end = zigTime.milliTimestamp();

    std.debug.print("Render completed in {}ms\n", .{renderTime});
    std.debug.print("File write completed in {}ms\n", .{end - fileWriteStart});
    std.debug.print("Total time {}ms\n", .{end - start});

    // std.debug.print("{any}", .{image});
}

pub fn loadScene() primitives.Scene {
    const sphere1 = primitives.Sphere{ .center = entities.Vector{ .points = .{ 0, 10000.5, 1.0 } }, .radius = 10000.0, .material = entities.Material{
        .chequered = true,
        .color = entities.Color{ .points = .{ 0.25882354, 0.019607844, 0 } },
        .color1 = entities.Color{ .points = .{ 0.9019608, 0.72156864, 0.49019608 } },
        .ambient = 0.2,
        .reflection = 0.2,
    } };
    const sphere2 = primitives.Sphere{ .center = entities.Vector{ .points = .{ 0.75, -0.1, 2.25 } }, .radius = 0.3, .material = entities.Material{
        .color = entities.Color{ .points = .{ 0, 0, 1.0 } },
    } };

    const sphere3 = primitives.Sphere{ .center = entities.Vector{ .points = .{ -0.75, -0.1, 1.0 } }, .radius = 0.3, .material = entities.Material{
        .color = entities.Color{ .points = .{ 0.5019608, 0.22352941, 0.5019608 } },
    } };

    const light1 = entities.Light{ .color = entities.Color{ .points = .{ 1.0, 1.0, 1.0 } }, .position = entities.Vector{ .points = .{ 1.5, -0.5, -10.0 } } };
    const light2 = entities.Light{ .color = entities.Color{ .points = .{ 0.9019608, 0.9019608, 0.9019608 } }, .position = entities.Vector{ .points = .{ -0.5, -10.5, 0 } } };
    const lights = [_]entities.Light{ light1, light2 };
    const objects = [_]primitives.Sphere{ sphere1, sphere2, sphere3 };

    const scene = primitives.Scene{
        .height = 1080,
        .width = 1920,

        .camera = entities.Vector{ .points = .{ 0, -0.35, -1 } },
        .lights = &lights,
        .objects = &objects,
    };
    return scene;
}

pub fn writeToFile(image: *entities.Image) !void {
    const file = try std.fs.cwd().createFile("one.ppm", .{ .truncate = true });
    defer file.close();

    var b: [1024]u8 = undefined;

    var w = file.writer(&b);
    var writer = &w.interface;

    // Write PPM header

    try writer.print("P3 {d} {d}\n255\n", .{ image.width, image.height });
    for (image.pixels) |color| {
        try writer.print("{d} {d} {d} ", .{ toByte(color.points[0]), toByte(color.points[1]), toByte(color.points[2]) });
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
