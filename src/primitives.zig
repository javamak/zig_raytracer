const std = @import("std");
const entities = @import("entities.zig");
const Allocator = std.mem.Allocator;
const testing = std.testing;

pub const Scene = struct {
    camera: entities.Vector,
    lights: []const entities.Light,
    objects: []const Sphere,

    width: i32 = 0,
    height: i32 = 0,
};

pub const Triangle = struct {
    p0: entities.Vector = entities.Vector{},
    p1: entities.Vector = entities.Vector{},
    p2: entities.Vector = entities.Vector{},

    const EPSILON: f32 = 0.0000001;

    pub const material: entities.Material = {};

    pub fn intersects(self: Triangle, ray: entities.Ray) ?f32 {
        const edge1 = self.p1.sub(self.p0);
        const edge2 = self.p2.sub(self.p0);
        const h = ray.direction.crossProduct(edge2);
        const a = edge1.dotProduct(h);

        if (a > -EPSILON and a < EPSILON) {
            return null;
        }

        const f = 1.0 / a;
        const s = ray.origin.sub(self.p0);

        const u = f * s.dotProduct(h);
        if (u < 0.0 or u > 1.0) {
            return null;
        }

        const q = s.crossProduct(edge1);
        const v = f * ray.direction.dotProduct(q);

        if (v < 0.0 or u + v > 1.0) {
            return null;
        }

        const t = f * edge2.dotProduct(q);

        if (t > EPSILON) {
            return t;
        }

        return null;
    }

    pub fn normal(self: Triangle, surfacePoint: entities.Vector) entities.Vector {
        const x = self.p1.sub(self.p0);
        const y = self.p2.sub(self.p0);

        return surfacePoint.sub(x.crossProduct(y)).normalize();
    }
};

pub const Sphere = struct {
    center: entities.Vector = entities.Vector{},
    radius: f32 = 0,
    material: entities.Material = entities.Material{},

    pub fn intersects(self: *const Sphere, ray: *const entities.Ray) ?f32 {
        const sphereToRay = ray.origin.sub(&self.center);
        const b = 2 * ray.direction.dotProduct(sphereToRay);
        const c = sphereToRay.dotProduct(sphereToRay) - (self.radius * self.radius);

        const disciminant = b * b - 4 * c;

        if (disciminant >= 0) {
            const dist = (-b - @sqrt(disciminant)) / 2.0;
            if (dist > 0) {
                return dist;
            }
        }

        return null;
    }

    pub fn normal(self: *const Sphere, surfacePoint: *const entities.Vector) entities.Vector {
        return surfacePoint.sub(&self.center).normalize();
    }
};

test "sphere intersects" {
    const sphere = Sphere{
        .radius = 10000.0,
        .center = .{ .x = 10.0, .y = 10000.5, .z = 1.0 },
    };

    const ray = entities.Ray{ .origin = .{ .x = 0.0, .y = -0.35, .z = 1.0 }, .direction = .{ .x = 0.5718716, .y = 0.55295265, .z = 0.6059755 } };

    const v = sphere.intersects(ray);
    std.debug.print("{?}\n", .{v});
    try testing.expectEqual(1.5437224, v);
}

test "sphere normal" {
    const sphere = Sphere{
        .center = .{ .x = 10.0, .y = 10.0, .z = 10.0 },
    };

    const sp: entities.Vector = .{ .x = 5.0, .y = 5.0, .z = 5.0 };
    const v = sphere.normal(&sp);
    const expected = entities.Vector{ .x = -0.57735026, .y = -0.57735026, .z = -0.57735026 };
    try testing.expectEqual(expected, v);
}
