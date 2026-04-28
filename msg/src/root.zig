const std = @import("std");

// sent by client
pub const ClientJoinLobby = struct { id: u32 };
pub const ClientCreateLobby = struct {};
pub const ClientInput = struct {
    throttle: i8,
    steering: i8,
};

// sent by server
pub const ServerPlayer = struct {
    id: u32,
    x: f32,
    y: f32,
    rotation: f32,
};
pub const ServerLobbyUpdate = struct {
    players: []const ServerPlayer,
};
pub const ServerLobbyJoined = struct {
    id: u32,
};

pub const Message = union(enum) {
    clientJoinLobby: ClientJoinLobby,
    clientCreateLobby: ClientCreateLobby,
    serverLobbyUpdate: ServerLobbyUpdate,
    clientInput: ClientInput,
    serverLobbyJoined: ServerLobbyJoined,

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
            .clientJoinLobby => Message{
                .clientJoinLobby = try decodeValue(allocator, reader, ClientJoinLobby),
            },
            .clientCreateLobby => Message{
                .clientCreateLobby = try decodeValue(allocator, reader, ClientCreateLobby),
            },
            .clientInput => Message{
                .clientInput = try decodeValue(allocator, reader, ClientInput),
            },
            .serverLobbyUpdate => Message{
                .serverLobbyUpdate = try decodeValue(allocator, reader, ServerLobbyUpdate),
            },
            .serverLobbyJoined => Message{
                .serverLobbyJoined = try decodeValue(allocator, reader, ServerLobbyJoined),
            },
        };
    }
};

fn encodeValue(writer: anytype, value: anytype) !void {
    const T = @TypeOf(value);

    switch (@typeInfo(T)) {
        .int => try writer.writeInt(T, value, .big),
        .float => {
            var bytes: [@sizeOf(T)]u8 = undefined;
            @memcpy(&bytes, std.mem.asBytes(&value));
            try writer.writeAll(&bytes);
        },

        .pointer => |p| {
            if (p.size == .slice) {
                if (p.child == u8) {
                    try writer.writeInt(u16, @intCast(value.len), .big);
                    try writer.writeAll(value);
                } else {
                    try writer.writeInt(u16, @intCast(value.len), .big);
                    for (value) |item| {
                        try encodeValue(writer, item);
                    }
                }
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
        .float => {
            var bytes: [@sizeOf(T)]u8 = undefined;
            try reader.readNoEof(&bytes);
            return @bitCast(bytes);
        },

        .pointer => |p| {
            if (p.size == .slice) {
                if (p.child == u8) {
                    const len = try reader.readInt(u16, .big);
                    const buf = try allocator.alloc(u8, len);
                    try reader.readNoEof(buf);
                    return buf;
                } else {
                    const len = try reader.readInt(u16, .big);
                    const arr = try allocator.alloc(p.child, len);
                    for (arr) |*item| {
                        item.* = try decodeValue(allocator, reader, p.child);
                    }
                    return arr;
                }
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
