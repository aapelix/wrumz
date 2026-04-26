const std = @import("std");

pub const Player = struct {
    x: f32,
    y: f32,
    rotation: f32,

    throttle: i8 = 0,
    steering: i8 = 0,

    velocity: f32 = 0,
    acceleration: f32 = 100,
    maxVelocity: f32 = 150,
    friction: f32 = 50,

    turnSpeed: f32 = 20,

    tireRotation: f32 = 0,
    tireTurnSpeed: f32 = 70,
    tireReturnSpeed: f32 = 80,
    tireMaxRotation: f32 = 30,

    pub fn update(self: *Player, dt: f32) void {
        if (self.throttle != 0) {
            self.velocity += @as(f32, @floatFromInt(self.throttle)) * self.acceleration * dt;
        } else if (self.velocity != 0) {
            const frictionEffect = self.friction * dt;
            if (self.velocity > 0) {
                self.velocity = if (self.velocity > frictionEffect) self.velocity - frictionEffect else 0;
            } else {
                self.velocity = if (self.velocity < -frictionEffect) self.velocity + frictionEffect else 0;
            }
        }

        self.velocity = if (self.velocity > self.maxVelocity) self.maxVelocity else if (self.velocity < -self.maxVelocity) -self.maxVelocity else self.velocity;

        if (self.steering != 0) {
            self.tireRotation += @as(f32, @floatFromInt(self.steering)) * self.tireTurnSpeed * dt;
        } else if (self.tireRotation != 0) {
            const returnEffect = self.tireReturnSpeed * dt;
            if (self.tireRotation > 0) {
                self.tireRotation = if (self.tireRotation > returnEffect) self.tireRotation - returnEffect else 0;
            } else {
                self.tireRotation = if (self.tireRotation < -returnEffect) self.tireRotation + returnEffect else 0;
            }
        }

        self.tireRotation = if (self.tireRotation > self.tireMaxRotation) self.tireMaxRotation else if (self.tireRotation < -self.tireMaxRotation) -self.tireMaxRotation else self.tireRotation;

        self.rotation += self.tireRotation * self.turnSpeed * dt * (self.velocity / self.maxVelocity);

        const rad = self.rotation * std.math.pi / 180;

        self.x += std.math.sin(rad) * self.velocity * dt;
        self.y -= std.math.cos(rad) * self.velocity * dt;
    }
};
