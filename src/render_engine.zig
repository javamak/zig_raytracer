const primitives = @import("primitives.zig");
const entities = @import("entities.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;

const MAX_DEPTH: u8 = 5;
const MIN_DISPLACE: f32 = 0.001;

pub fn render(scene: *const primitives.Scene, gpa: Allocator) !*entities.Image {
    const width: f32 = @floatFromInt(scene.width);
    const height: f32 = @floatFromInt(scene.height);

    const aspect_ratio: f32 = width / height;

    const x0: f32 = -1.0;

    const xstep = (1.0 - x0) / (width - 1);

    const y0 = -1.0 / aspect_ratio;
    const y1 = 1.0 / aspect_ratio;
    const ystep = (y1 - y0) / (height - 1);

    const pixels = try gpa.alloc(entities.Color, @intCast(scene.height * scene.width));
    //var image = entities.Image{ .width = scene.width, .height = scene.height, .pixels = pixels };
    var image = try gpa.create(entities.Image);
    image.height = scene.height;
    image.width = scene.width;
    image.pixels = pixels;

    var row: i32 = 0;

    while (row < scene.height) : (row += 1) {
        const y = y0 + @as(f32, @floatFromInt(row)) * ystep;
        var col: i32 = 0;
        while (col < scene.width) : (col += 1) {
            const x = x0 + @as(f32, @floatFromInt(col)) * xstep;
            const v = entities.Vector{ .x = x, .y = y, .z = 0.0 };

            const ray = entities.Ray{ .origin = scene.camera, .direction = v.sub(&scene.camera).normalize() };
            const color = rayTrace(ray, scene, 0);
            image.setPixel(col, row, color);
        }
    }
    return image;
}

fn rayTrace(ray: entities.Ray, scene: *const primitives.Scene, depth: u8) entities.Color {
    var color = entities.Color{};
    //find the nearest object hit by the ray in the scene
    const hit = find_nearest(ray, scene) orelse return color;
    const hitObject = hit.object orelse return color;

    const mul = ray.direction.mul(hit.distance);
    const hitPos = ray.origin.add(&mul);
    const hitNormal = hitObject.normal(&hitPos);

    // std.debug.print("\n\n\nDepth : {d}\n", .{depth});
    // std.debug.print("Ray: {any}\n", .{ray});
    // std.debug.print("Hit obj: {any}\n", .{hit.object});
    // std.debug.print("Hit dis: {d}\n", .{hit.distance});
    // std.debug.print("Hit Pos: {any}\n", .{hitPos});
    // std.debug.print("Hit Normal: {any}\n", .{hitNormal});

    if (depth < MAX_DEPTH) {
        const dd = hitNormal.mul(MIN_DISPLACE);
        const newRayPos = hitPos.add(&dd);
        const hitNormalMul = hitNormal.mul(2 * ray.direction.dotProduct(hitNormal));

        const newRayDir = ray.direction.sub(&hitNormalMul);
        const newRay = entities.Ray{ .origin = newRayPos, .direction = newRayDir.normalize() };
        //Attenuate the reflected ray found by reflection coefficient
        const c = rayTrace(newRay, scene, depth + 1);
        const c1 = c.mul(hitObject.material.reflection);
        color = color.add(&c1);
    } else {
        const c1 = colorAt(&hitObject, &hitPos, &hitNormal, scene);
        // std.debug.print("Color at depth{d}: {any}\n", .{ depth, c1 });
        color = color.add(&c1);
    }

    // std.debug.print("Color at depth{d}: {any}\n", .{ depth, color });
    return color;
}

const HitPos = struct { distance: f32, object: ?primitives.Sphere };

fn find_nearest(ray: entities.Ray, scene: *const primitives.Scene) ?HitPos {
    var objHit: ?primitives.Sphere = null;
    var distMin: f32 = 0;
    for (scene.objects) |obj| {
        const dist = obj.intersects(ray) orelse continue;
        if (objHit == null or dist < distMin) {
            distMin = dist;
            objHit = obj;
        }
    }
    return HitPos{ .distance = distMin, .object = objHit };
}

fn colorAt(object: *const primitives.Sphere, hitPos: *const entities.Vector, hitNormal: *const entities.Vector, scene: *const primitives.Scene) entities.Color {
    const material = object.material;
    const objColor = material.colorAt(hitPos);
    const toCam = scene.camera.sub(hitPos);
    const specular_k = 50;
    //var color = entities.Color.fromHex(("#000000")).mul(material.ambient);
    var color = (entities.Color{}).mul(material.ambient);
    for (scene.lights) |light| {
        const toLight = entities.Ray{ .origin = hitPos.*, .direction = light.position.sub(hitPos).normalize() };
        // std.debug.print("\n\nLight: {any}\n", .{light});
        // std.debug.print("Hitpos within ColorAt: {any}\n", .{hitPos});
        // std.debug.print("Ray within colorAt: {any}\n", .{toLight});

        //diffuse shading (Lambert)
        const c1 = objColor.mul(material.diffuse).mul(@max(hitNormal.dotProduct(toLight.direction), 0));
        color = color.add(&c1);
        //specualar shadding (Blinn-Phong)
        const halfVector = toLight.direction.add(&toCam).normalize();
        const c2 = light.color.mul(material.specular).mul(pow(@max(hitNormal.dotProduct(halfVector), 0), specular_k));
        color = color.add(&c2);
    }
    return color;
}

fn pow(n: f32, p: usize) f32 {
    var res: f32 = 1;
    for (0..p) |_| {
        res *= n;
    }
    return res;
}

const testing = std.testing;

test "test pow" {
    try testing.expectEqual(8, pow(2, 3));
}

test "ray trace" {
    const main = @import("main.zig");

    const scene = main.loadScene();

    //Ray: Ray{origin=Vector{x=0.0, y=-0.35, z=-1.0}, direction=Vector{x=0.19470401, y=0.10190647, z=0.9755539}}
    //Color: Color{r=0.004891529, g=0.0039132233, b=0.0026584396}

    const ray = entities.Ray{ .origin = .{ .x = 0.0, .y = -0.35, .z = -1.0 }, .direction = .{ .x = 0.19470401, .y = 0.10190647, .z = 0.9755539 } };

    const color = rayTrace(ray, &scene, 0);
    std.debug.print("{any}", .{color});
}
