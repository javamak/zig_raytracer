const std = @import("std");
const testing = std.testing;

pub const Vector = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn add(self: *const Vector, other: *const Vector) Vector {
        return .{ .x = self.x + other.x, .y = self.y + other.y, .z = self.z + other.z };
    }

    pub fn sub(self: *const Vector, other: *const Vector) Vector {
        return .{ .x = self.x - other.x, .y = self.y - other.y, .z = self.z - other.z };
    }

    pub fn mul(self: *const Vector, scalar: f32) Vector {
        return .{ .x = self.x * scalar, .y = self.y * scalar, .z = self.z * scalar };
    }

    pub fn div(self: *const Vector, scalar: f32) Vector {
        return .{ .x = self.x / scalar, .y = self.y / scalar, .z = self.z / scalar };
    }

    pub fn magnitude(self: *const Vector) f32 {
        return @sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }
    pub fn normalize(self: *const Vector) Vector {
        return self.div(self.magnitude());
    }

    pub fn dotProduct(self: *const Vector, other: Vector) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn crossProduct(self: *const Vector, other: Vector) Vector {
        const x = self.y * other.z - self.z * other.y;
        const y = self.z * other.x - self.x * other.z;
        const z = self.x * other.y - self.y * other.x;

        return Vector{ .x = x, .y = y, .z = z };
    }
};
pub const Color = struct {
    r: f32 = 0,
    g: f32 = 0,
    b: f32 = 0,

    pub fn add(self: *const Color, other: *const Color) Color {
        return Color{
            .r = self.r + other.r,
            .g = self.g + other.g,
            .b = self.b + other.b,
        };
    }

    pub fn mul(self: *const Color, scalar: f32) Color {
        return Color{
            .r = self.r * scalar,
            .g = self.g * scalar,
            .b = self.b * scalar,
        };
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
            const x = @mod((position.x + 5.0) * 3.0, 2);
            const y = @mod((position.z + 5.0) * 3.0, 2);
            if (x == y) {
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
    width: i32,
    height: i32,

    pixels: []Color,

    pub fn setPixel(self: *Image, col: i32, row: i32, color: Color) void {
        self.pixels[@intCast(row * self.width + col)] = color;
    }
};

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
    const v = Vector{ .x = 10.0, .y = 10.2, .z = 10.3 };
    try testing.expectEqual(17.61050796508789, v.magnitude());
}

test "test normalize" {
    const v = Vector{ .x = 10.0, .y = 10.2, .z = 10.3 };
    try testing.expectEqual(Vector{ .x = 0.5678428, .y = 0.5791996, .z = 0.5848781 }, v.normalize());
}

test "test dotProduct" {
    const v = Vector{ .x = 10.0, .y = 10.2, .z = 10.3 };
    const v1 = Vector{ .x = 10.0, .y = 10.2, .z = 10.3 };
    try testing.expectEqual(310.13, v.dotProduct(v1));
}

test "test crossProduct same vectors" {
    const v = Vector{ .x = 10.0, .y = 10.2, .z = 10.3 };
    try testing.expectEqual(Vector{}, v.crossProduct(v));
}

test "test crossProduct different vectors" {
    const v = Vector{ .x = 10.0, .y = 10.2, .z = 10.3 };
    const v1 = Vector{ .x = 10.1, .y = 10.1, .z = 10.1 };

    try testing.expectEqual(Vector{ .x = -1.0100021, .y = 3.0300064, .z = -2.0200043 }, v.crossProduct(v1));
}
