const std = @import("std");
const types = @import("types.zig");

// Decoding utilities
pub const Decoder = struct {
    data: []const u8,
    pos: usize = 0,

    pub fn init(data: []const u8) Decoder {
        return .{ .data = data };
    }

    // Check if we have more data
    pub fn hasMore(self: Decoder) bool {
        return self.pos < self.data.len;
    }

    // Get remaining data
    pub fn remaining(self: Decoder) []const u8 {
        return self.data[self.pos..];
    }

    // Decode a varint
    pub fn decodeVarint(self: *Decoder) !u64 {
        var result: u64 = 0;
        var shift: u6 = 0;

        while (self.pos < self.data.len) {
            const byte = self.data[self.pos];
            self.pos += 1;

            result |= @as(u64, byte & 0x7F) << shift;

            if (byte & 0x80 == 0) {
                return result;
            }

            shift += 7;
            if (shift >= 64) {
                return error.VarintTooLong;
            }
        }

        return error.UnexpectedEndOfData;
    }

    // Decode a signed varint (zigzag decoding)
    pub fn decodeZigZag(self: *Decoder) !i64 {
        const encoded = try self.decodeVarint();
        return zigzagDecode(encoded);
    }

    // Decode fixed 32-bit value
    pub fn decodeFixed32(self: *Decoder) !u32 {
        if (self.pos + 4 > self.data.len) {
            return error.UnexpectedEndOfData;
        }

        const bytes = self.data[self.pos..][0..4];
        self.pos += 4;

        return @as(u32, @bitCast(bytes));
    }

    // Decode fixed 64-bit value
    pub fn decodeFixed64(self: *Decoder) !u64 {
        if (self.pos + 8 > self.data.len) {
            return error.UnexpectedEndOfData;
        }

        const bytes = self.data[self.pos..][0..8];
        self.pos += 8;

        return @as(u64, @bitCast(bytes));
    }

    // Decode float
    pub fn decodeFloat(self: *Decoder) !f32 {
        const bits = try self.decodeFixed32();
        return @as(f32, @bitCast(bits));
    }

    // Decode double
    pub fn decodeDouble(self: *Decoder) !f64 {
        const bits = try self.decodeFixed64();
        return @as(f64, @bitCast(bits));
    }

    // Decode length-delimited field
    pub fn decodeLengthDelimited(self: *Decoder, allocator: std.mem.Allocator) ![]const u8 {
        const length = try self.decodeVarint();
        if (self.pos + length > self.data.len) {
            return error.UnexpectedEndOfData;
        }

        const result = self.data[self.pos..][0..length];
        self.pos += length;

        // Copy the data so caller owns it
        const copy = try allocator.alloc(u8, length);
        @memcpy(copy, result);
        return copy;
    }

    // Decode a tag (field number + wire type)
    pub fn decodeTag(self: *Decoder) !struct { field_number: u32, wire_type: types.WireType } {
        const tag = try self.decodeVarint();
        const field_number = @as(u32, @intCast(tag >> 3));
        const wire_type = @as(types.WireType, @enumFromInt(@as(u3, @intCast(tag & 0x07))));

        return .{
            .field_number = field_number,
            .wire_type = wire_type,
        };
    }

    // Skip a field based on wire type
    pub fn skipField(self: *Decoder, wire_type: types.WireType) !void {
        switch (wire_type) {
            .varint => {
                _ = try self.decodeVarint();
            },
            .fixed64 => {
                if (self.pos + 8 > self.data.len) {
                    return error.UnexpectedEndOfData;
                }
                self.pos += 8;
            },
            .length_delimited => {
                const length = try self.decodeVarint();
                if (self.pos + length > self.data.len) {
                    return error.UnexpectedEndOfData;
                }
                self.pos += length;
            },
            .start_group => {
                // Skip until matching end_group
                var depth: u32 = 1;
                while (depth > 0) {
                    const tag = try self.decodeTag();
                    switch (tag.wire_type) {
                        .start_group => depth += 1,
                        .end_group => depth -= 1,
                        else => try self.skipField(tag.wire_type),
                    }
                }
            },
            .end_group => return error.UnexpectedEndGroup,
            .fixed32 => {
                if (self.pos + 4 > self.data.len) {
                    return error.UnexpectedEndOfData;
                }
                self.pos += 4;
            },
        }
    }

    // Decode a field value based on wire type and field type
    pub fn decodeFieldValue(
        self: *Decoder,
        allocator: std.mem.Allocator,
        field: *const types.Field,
        wire_type: types.WireType,
    ) !types.FieldValue {
        // Handle packed repeated fields
        if (field.is_packed and wire_type == .length_delimited) {
            const packed_data = try self.decodeLengthDelimited(allocator);
            defer allocator.free(packed_data);

            var packed_decoder = Decoder.init(packed_data);
            var repeated = types.RepeatedValue.init(allocator, field.field_type);

            while (packed_decoder.hasMore()) {
                const value = try decodeSingleValue(&packed_decoder, allocator, field.field_type);
                try repeated.add(value);
            }

            return types.FieldValue{ .repeated = &repeated };
        }

        // Handle regular fields
        const value = try decodeSingleValue(self, allocator, field.field_type);

        if (field.repeated) {
            var repeated = types.RepeatedValue.init(allocator, field.field_type);
            try repeated.add(value);
            return types.FieldValue{ .repeated = &repeated };
        }

        return value;
    }

    // Decode a complete message
    pub fn decodeMessage(
        self: *Decoder,
        allocator: std.mem.Allocator,
        descriptor: *const types.MessageDescriptor,
    ) !types.MessageInstance {
        var message = types.MessageInstance.init(allocator, descriptor);

        while (self.hasMore()) {
            const tag = try self.decodeTag();

            if (descriptor.getField(tag.field_number)) |field| {
                const value = try self.decodeFieldValue(allocator, field, tag.wire_type);
                try message.setValue(field.index, value);
            } else {
                // Skip unknown field
                try self.skipField(tag.wire_type);
            }
        }

        return message;
    }
};

// Helper functions
fn zigzagDecode(encoded: u64) i64 {
    return @as(i64, @bitCast((encoded >> 1) ^ (~(encoded & 1) + 1)));
}

fn decodeSingleValue(
    decoder: *Decoder,
    allocator: std.mem.Allocator,
    field_type: types.FieldType,
) !types.FieldValue {
    return switch (field_type) {
        .int32 => types.FieldValue{ .int32 = @as(i32, @intCast(try decoder.decodeVarint())) },
        .int64 => types.FieldValue{ .int64 = @as(i64, @intCast(try decoder.decodeVarint())) },
        .sint32 => types.FieldValue{ .sint32 = @as(i32, @intCast(try decoder.decodeZigZag())) },
        .sint64 => types.FieldValue{ .sint64 = try decoder.decodeZigZag() },
        .uint32 => types.FieldValue{ .uint32 = @as(u32, @intCast(try decoder.decodeVarint())) },
        .uint64 => types.FieldValue{ .uint64 = try decoder.decodeVarint() },
        .bool => types.FieldValue{ .bool = (try decoder.decodeVarint()) != 0 },
        .@"enum" => types.FieldValue{ .@"enum" = @as(i32, @intCast(try decoder.decodeVarint())) },
        .fixed32 => types.FieldValue{ .fixed32 = try decoder.decodeFixed32() },
        .sfixed32 => types.FieldValue{ .sfixed32 = @as(i32, @bitCast(try decoder.decodeFixed32())) },
        .float => types.FieldValue{ .float = try decoder.decodeFloat() },
        .fixed64 => types.FieldValue{ .fixed64 = try decoder.decodeFixed64() },
        .sfixed64 => types.FieldValue{ .sfixed64 = @as(i64, @bitCast(try decoder.decodeFixed64())) },
        .double => types.FieldValue{ .double = try decoder.decodeDouble() },
        .string => types.FieldValue{ .string = try decoder.decodeLengthDelimited(allocator) },
        .bytes => types.FieldValue{ .bytes = try decoder.decodeLengthDelimited(allocator) },
        .message => return error.CannotDecodeMessageWithoutDescriptor,
        else => return error.UnsupportedFieldType,
    };
}

// Public API functions
pub fn decodePrimitive(
    allocator: std.mem.Allocator,
    data: []const u8,
    field_type: types.FieldType,
) !struct { value: types.FieldValue, bytes_read: usize } {
    var decoder = Decoder.init(data);
    const start_pos = decoder.pos;

    const value = try decodeSingleValue(&decoder, allocator, field_type);
    const bytes_read = decoder.pos - start_pos;

    return .{ .value = value, .bytes_read = bytes_read };
}

pub fn decodeMessageData(
    allocator: std.mem.Allocator,
    data: []const u8,
    descriptor: *const types.MessageDescriptor,
) !types.MessageInstance {
    var decoder = Decoder.init(data);
    return try decoder.decodeMessage(allocator, descriptor);
}