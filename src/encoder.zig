const std = @import("std");
const types = @import("types.zig");

// Encoding utilities
pub const Encoder = struct {
    allocator: std.mem.Allocator,
    buffer: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) Encoder {
        return .{
            .allocator = allocator,
            .buffer = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *Encoder) void {
        self.buffer.deinit();
    }

    pub fn toSlice(self: Encoder) []const u8 {
        return self.buffer.items;
    }

    // Encode a varint
    pub fn encodeVarint(self: *Encoder, value: u64) void {
        var v = value;
        while (true) {
            const byte = @as(u8, @intCast(v & 0x7F));
            v >>= 7;
            if (v == 0) {
                self.buffer.append(byte) catch unreachable;
                break;
            } else {
                self.buffer.append(byte | 0x80) catch unreachable;
            }
        }
    }

    // Encode a signed varint (zigzag encoding)
    pub fn encodeZigZag(self: *Encoder, value: i64) void {
        const encoded = zigzagEncode(value);
        self.encodeVarint(encoded);
    }

    // Encode fixed 32-bit value
    pub fn encodeFixed32(self: *Encoder, value: u32) void {
        const bytes = @as([4]u8, @bitCast(value));
        self.buffer.appendSlice(&bytes) catch unreachable;
    }

    // Encode fixed 64-bit value
    pub fn encodeFixed64(self: *Encoder, value: u64) void {
        const bytes = @as([8]u8, @bitCast(value));
        self.buffer.appendSlice(&bytes) catch unreachable;
    }

    // Encode float
    pub fn encodeFloat(self: *Encoder, value: f32) void {
        const bits = @as(u32, @bitCast(value));
        self.encodeFixed32(bits);
    }

    // Encode double
    pub fn encodeDouble(self: *Encoder, value: f64) void {
        const bits = @as(u64, @bitCast(value));
        self.encodeFixed64(bits);
    }

    // Encode length-delimited field (string/bytes/message)
    pub fn encodeLengthDelimited(self: *Encoder, data: []const u8) void {
        self.encodeVarint(@as(u64, data.len));
        self.buffer.appendSlice(data) catch unreachable;
    }

    // Encode field tag (field number + wire type)
    pub fn encodeTag(self: *Encoder, field_number: u32, wire_type: types.WireType) void {
        const tag = (field_number << 3) | @intFromEnum(wire_type);
        self.encodeVarint(tag);
    }

    // Encode a field value based on its type
    pub fn encodeFieldValue(self: *Encoder, field: *const types.Field, value: types.FieldValue) !void {
        switch (value) {
            .int32 => |v| {
                self.encodeTag(field.index, .varint);
                self.encodeVarint(@as(u64, @bitCast(@as(i64, v))));
            },
            .int64 => |v| {
                self.encodeTag(field.index, .varint);
                self.encodeVarint(@as(u64, @bitCast(v)));
            },
            .sint32 => |v| {
                self.encodeTag(field.index, .varint);
                self.encodeZigZag(v);
            },
            .sint64 => |v| {
                self.encodeTag(field.index, .varint);
                self.encodeZigZag(v);
            },
            .uint32 => |v| {
                self.encodeTag(field.index, .varint);
                self.encodeVarint(v);
            },
            .uint64 => |v| {
                self.encodeTag(field.index, .varint);
                self.encodeVarint(v);
            },
            .bool => |v| {
                self.encodeTag(field.index, .varint);
                self.encodeVarint(if (v) 1 else 0);
            },
            .@"enum" => |v| {
                self.encodeTag(field.index, .varint);
                self.encodeVarint(@as(u64, @bitCast(@as(i64, v))));
            },
            .fixed32 => |v| {
                self.encodeTag(field.index, .fixed32);
                self.encodeFixed32(v);
            },
            .sfixed32 => |v| {
                self.encodeTag(field.index, .fixed32);
                self.encodeFixed32(@as(u32, @bitCast(v)));
            },
            .float => |v| {
                self.encodeTag(field.index, .fixed32);
                self.encodeFloat(v);
            },
            .fixed64 => |v| {
                self.encodeTag(field.index, .fixed64);
                self.encodeFixed64(v);
            },
            .sfixed64 => |v| {
                self.encodeTag(field.index, .fixed64);
                self.encodeFixed64(@as(u64, @bitCast(v)));
            },
            .double => |v| {
                self.encodeTag(field.index, .fixed64);
                self.encodeDouble(v);
            },
            .string => |v| {
                self.encodeTag(field.index, .length_delimited);
                self.encodeLengthDelimited(v);
            },
            .bytes => |v| {
                self.encodeTag(field.index, .length_delimited);
                self.encodeLengthDelimited(v);
            },
            .message => |msg| {
                // Encode sub-message
                var sub_encoder = Encoder.init(self.allocator);
                defer sub_encoder.deinit();
                try encodeMessage(&sub_encoder, msg);

                self.encodeTag(field.index, .length_delimited);
                self.encodeLengthDelimited(sub_encoder.toSlice());
            },
            .repeated => |rep| {
                if (field.is_packed and field.isNumeric()) {
                    // Encode as packed repeated field
                    self.encodeTag(field.index, .length_delimited);

                    var packed_encoder = Encoder.init(self.allocator);
                    defer packed_encoder.deinit();

                    for (rep.values.items) |item| {
                        try encodePackedValue(&packed_encoder, field.field_type, item);
                    }

                    self.encodeLengthDelimited(packed_encoder.toSlice());
                } else {
                    // Encode as separate fields
                    for (rep.values.items) |item| {
                        self.encodeTag(field.index, field.wireType());
                        try encodeSingleValue(self, field.field_type, item);
                    }
                }
            },
        }
    }

    // Encode a complete message
    pub fn encodeMessage(self: *Encoder, message: *types.MessageInstance) !void {
        // Sort fields by index for deterministic output
        var field_indices = std.ArrayList(u32).init(self.allocator);
        defer field_indices.deinit();

        var it = message.values.iterator();
        while (it.next()) |entry| {
            try field_indices.append(entry.key_ptr.*);
        }

        std.sort.insertion(u32, field_indices.items, {}, std.sort.asc(u32));

        // Encode each field
        for (field_indices.items) |field_index| {
            if (message.descriptor.getField(field_index)) |field| {
                if (message.values.get(field_index)) |value| {
                    try self.encodeFieldValue(field, value);
                }
            }
        }
    }
};

// Helper functions
fn zigzagEncode(value: i64) u64 {
    return @as(u64, @bitCast((value << 1) ^ (value >> 63)));
}

fn encodeSingleValue(encoder: *Encoder, field_type: types.FieldType, value: types.FieldValue) !void {
    switch (field_type) {
        .int32 => encoder.encodeVarint(@as(u64, @bitCast(@as(i64, value.int32)))),
        .int64 => encoder.encodeVarint(@as(u64, @bitCast(value.int64))),
        .sint32 => encoder.encodeZigZag(value.sint32),
        .sint64 => encoder.encodeZigZag(value.sint64),
        .uint32 => encoder.encodeVarint(value.uint32),
        .uint64 => encoder.encodeVarint(value.uint64),
        .bool => encoder.encodeVarint(if (value.bool) 1 else 0),
        .@"enum" => encoder.encodeVarint(@as(u64, @bitCast(@as(i64, value.@"enum")))),
        .fixed32 => encoder.encodeFixed32(value.fixed32),
        .sfixed32 => encoder.encodeFixed32(@as(u32, @bitCast(value.sfixed32))),
        .float => encoder.encodeFloat(value.float),
        .fixed64 => encoder.encodeFixed64(value.fixed64),
        .sfixed64 => encoder.encodeFixed64(@as(u64, @bitCast(value.sfixed64))),
        .double => encoder.encodeDouble(value.double),
        .string => encoder.encodeLengthDelimited(value.string),
        .bytes => encoder.encodeLengthDelimited(value.bytes),
        .message => unreachable, // Should be handled separately
        else => return error.UnsupportedFieldType,
    }
}

fn encodePackedValue(encoder: *Encoder, field_type: types.FieldType, value: types.FieldValue) !void {
    return encodeSingleValue(encoder, field_type, value);
}

// Public API functions
pub fn encodePrimitive(allocator: std.mem.Allocator, field_type: types.FieldType, value: types.FieldValue) ![]const u8 {
    var encoder = Encoder.init(allocator);
    defer encoder.deinit();

    try encodeSingleValue(&encoder, field_type, value);
    return encoder.buffer.toOwnedSlice();
}

pub fn encodeMessageData(allocator: std.mem.Allocator, message: *types.MessageInstance) ![]const u8 {
    var encoder = Encoder.init(allocator);
    defer encoder.deinit();

    try encoder.encodeMessage(message);
    return encoder.buffer.toOwnedSlice();
}