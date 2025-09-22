const std = @import("std");
const testing = std.testing;

pub const Vector = struct {
    points: @Vector(3, f32) = .{ 0, 0, 0 },
    // x: f32 = 0,
    // y: f32 = 0,
    // z: f32 = 0,

    pub inline fn add(self: *const Vector, other: *const Vector) Vector {
        //return .{ .x = self.x + other.x, .y = self.y + other.y, .z = self.z + other.z };
        return .{ .points = self.points + other.points };
    }

    pub inline fn sub(self: *const Vector, other: *const Vector) Vector {
        return .{ .points = self.points - other.points };
    }

    pub inline fn mul(self: *const Vector, scalar: f32) Vector {
        const multiplier: @Vector(3, f32) = @splat(scalar);
        return .{ .points = self.points * multiplier };
    }

    pub inline fn div(self: *const Vector, scalar: f32) Vector {
        const divider: @Vector(3, f32) = @splat(scalar);
        return .{ .points = self.points / divider };
    }

    pub inline fn magnitude(self: *const Vector) f32 {
        const squared = self.points * self.points;
        const sum = @reduce(.Add, squared);
        return @sqrt(sum);
    }

    pub inline fn normalize(self: *const Vector) Vector {
        return self.div(self.magnitude());
    }

    pub inline fn dotProduct(self: *const Vector, other: Vector) f32 {
        const squared = self.points * other.points;
        return @reduce(.Add, squared);
    }

    pub inline fn crossProduct(self: *const Vector, other: Vector) Vector {
        const x = self.points[1] * other.points[2] - self.points[2] * other.points[1];
        const y = self.points[2] * other.points[0] - self.points[0] * other.points[2];
        const z = self.points[0] * other.points[1] - self.points[1] * other.points[0];

        return Vector{ .points = .{ x, y, z } };
    }
};
pub const Color = struct {
    points: @Vector(3, f32) = .{ 0, 0, 0 },

    pub inline fn addSelf(self: *Color, other: *const Color) void {
        self.points = self.points + other.points;
    }

    pub inline fn mul(self: *const Color, scalar: f32) Color {
        const multiplier: @Vector(3, f32) = @splat(scalar);
        return Color{ .points = self.points * multiplier };
    }
};

pub const Material = struct {
    color: Color = Color{},
    ambient: f32 = 0.5,
    diffuse: f32 = 1.0,
    specular: f32 = 1.0,
    reflection: f32 = 0.5,
    chequered: bool = false,
    color1: Color = Color{},

    pub fn colorAt(self: *const Material, position: *const Vector) Color {
        if (self.chequered) {
            const x = @mod((position.points[0] + 5.0) * 3.0, 2);
            const y = @mod((position.points[2] + 5.0) * 3.0, 2);
            if (@as(i32, @intFromFloat(x)) == @as(i32, @intFromFloat(y))) {
                return self.color;
            }
            return self.color1;
        } else {
            return self.color;
        }
    }
};

pub const Light = struct {
    position: Vector = Vector{},
    color: Color = Color{},

    fn fromHex(_: []u8) Color {
        return Color{};
    }
};

pub const Ray = struct {
    origin: Vector = Vector{},
    direction: Vector = Vector{},
};

pub const Image = struct {
    width: u32,
    height: u32,

    pixels: []Color,

    pub inline fn setPixel(self: *Image, col: usize, row: usize, color: Color) void {
        self.pixels[@intCast(row * self.width + col)] = color;
    }
};

test "Vector sub" {
    const pos = Vector{ .points = .{ 1.5, -0.5, -10 } };
    const hit: Vector = .{ .points = .{ -1.3911865, 0.50031936, 0.69772184 } };

    std.debug.print("{any}\n", .{pos.sub(&hit)});

    //.{ .x = 2.8911865, .y = -1.0003194, .z = -10.6977215 }
}

test "subtract positive" {
    std.debug.print("{d}\n", .{1 - (-10)});
}

test "set pixel" {
    const pixels = try testing.allocator.alloc(Color, 40);
    defer testing.allocator.free(pixels);
    var image = Image{
        .height = 10,
        .width = 4,
        .pixels = pixels,
    };

    const color = Color{ .r = 1, .g = 1, .b = 1 };
    image.setPixel(0, 0, Color{ .r = 1, .g = 1, .b = 1 });

    try testing.expectEqual(color, image.pixels[0]);

    image.setPixel(3, 9, Color{ .r = 1, .g = 1, .b = 1 });

    try testing.expectEqual(color, image.pixels[39]);
}

test "test magnitude" {
    const v = Vector{ .points = .{ 10.0, 10.2, 10.3 } };
    try testing.expectEqual(17.61050796508789, v.magnitude());
}

test "test normalize" {
    const v = Vector{ .points = .{ 10.0, 10.2, 10.3 } };
    try testing.expectEqual(Vector{ .points = .{ 0.5678428, 0.5791996, 0.5848781 } }, v.normalize());
}

test "test dotProduct" {
    const v = Vector{ .points = .{ 10.0, 10.2, 10.3 } };
    const v1 = Vector{ .points = .{ 10.0, 10.2, 10.3 } };
    try testing.expectEqual(310.13, v.dotProduct(v1));
}

test "test crossProduct same vectors" {
    const v = Vector{ .points = .{ 10.0, 10.2, 10.3 } };
    try testing.expectEqual(Vector{}, v.crossProduct(v));
}

test "test crossProduct different vectors" {
    const v = Vector{ .points = .{ 10.0, 10.2, 10.3 } };
    const v1 = Vector{ .points = .{ 10.1, 10.1, 10.1 } };

    try testing.expectEqual(Vector{ .points = .{ -1.0100021, 3.0300064, -2.0200043 } }, v.crossProduct(v1));
}
