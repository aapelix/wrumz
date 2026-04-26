const std = @import("std");

pub const Ping = struct {
    username: []const u8,
};

pub const Message = union(enum) {
    ping: Ping,

    pub fn encode(msg: Message, writer: anytype) !void {
        try writer.writeByte(@intFromEnum(msg));

        switch (msg) {
            inline else => |payload| {
                try encodeValue(writer, payload);
            },
        }
    }
    pub fn decode(allocator: std.mem.Allocator, reader: anytype) !Message {
        const tag = try reader.readByte();
        const Tag = std.meta.Tag(Message);

        return switch (@as(Tag, @enumFromInt(tag))) {
            .ping => Message{
                .ping = try decodeValue(allocator, reader, Ping),
            },
        };
    }
};

fn encodeValue(writer: anytype, value: anytype) !void {
    const T = @TypeOf(value);

    switch (@typeInfo(T)) {
        .int => try writer.writeInt(T, value, .big),

        .pointer => |p| {
            if (p.size == .slice and p.child == u8) {
                try writer.writeInt(u16, @intCast(value.len), .big);
                try writer.writeAll(value);
            } else {
                @compileError("unsupported pointer type");
            }
        },

        .@"struct" => {
            inline for (@typeInfo(T).@"struct".fields) |field| {
                try encodeValue(writer, @field(value, field.name));
            }
        },

        else => @compileError("unsupported type"),
    }
}

fn decodeValue(allocator: std.mem.Allocator, reader: anytype, comptime T: type) !T {
    switch (@typeInfo(T)) {
        .int => return try reader.readInt(T, .big),

        .pointer => |p| {
            if (p.size == .slice and p.child == u8) {
                const len = try reader.readInt(u16, .big);
                const buf = try allocator.alloc(u8, len);
                try reader.readNoEof(buf);
                return buf;
            } else {
                @compileError("unsupported pointer type");
            }
        },

        .@"struct" => {
            var out: T = undefined;
            inline for (@typeInfo(T).@"struct".fields) |field| {
                @field(out, field.name) = try decodeValue(allocator, reader, field.type);
            }
            return out;
        },

        else => @compileError("unsupported type"),
    }
}
