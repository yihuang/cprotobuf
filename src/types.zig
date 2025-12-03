const std = @import("std");
const py = @import("pydust");

// Wire type constants
pub const WireType = enum(u3) {
    varint = 0,
    fixed64 = 1,
    length_delimited = 2,
    start_group = 3,
    end_group = 4,
    fixed32 = 5,
};

// Field type mapping
pub const FieldType = enum {
    int32,
    int64,
    sint32,
    sint64,
    uint32,
    uint64,
    bool,
    @"enum",
    fixed64,
    sfixed64,
    double,
    string,
    bytes,
    fixed32,
    sfixed32,
    float,
    message, // For sub-messages
};

// Field descriptor
pub const Field = struct {
    name: []const u8,
    field_type: FieldType,
    index: u32,
    required: bool = true,
    repeated: bool = false,
    is_packed: bool = false,
    default: ?[]const u8 = null,
    message_type: ?[]const u8 = null, // For message fields

    // Get wire type for this field
    pub fn wireType(self: Field) WireType {
        if (self.is_packed) return .length_delimited;

        return switch (self.field_type) {
            .int32, .int64, .sint32, .sint64, .uint32, .uint64, .bool, .@"enum" => .varint,
            .fixed64, .sfixed64, .double => .fixed64,
            .string, .bytes, .message => .length_delimited,
            .fixed32, .sfixed32, .float => .fixed32,
        };
    }

    // Check if field type is numeric (for packed encoding)
    pub fn isNumeric(self: Field) bool {
        return switch (self.field_type) {
            .int32, .int64, .sint32, .sint64, .uint32, .uint64, .bool, .@"enum",
            .fixed64, .sfixed64, .double, .fixed32, .sfixed32, .float => true,
            .string, .bytes, .message => false,
        };
    }
};

// Message descriptor
pub const MessageDescriptor = struct {
    name: []const u8,
    fields: std.AutoArrayHashMap(u32, Field), // index -> field
    fields_by_name: std.StringArrayHashMap(*Field),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, name: []const u8) MessageDescriptor {
        return .{
            .name = name,
            .fields = std.AutoArrayHashMap(u32, Field).init(allocator),
            .fields_by_name = std.StringArrayHashMap(*Field).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *MessageDescriptor) void {
        self.fields.deinit();
        self.fields_by_name.deinit();
    }

    pub fn addField(self: *MessageDescriptor, field: Field) !void {
        // Store field
        try self.fields.put(field.index, field);

        // Get pointer to stored field
        const entry = self.fields.getPtr(field.index).?;
        try self.fields_by_name.put(field.name, entry);
    }

    pub fn getField(self: MessageDescriptor, index: u32) ?*const Field {
        return self.fields.getPtr(index);
    }

    pub fn getFieldByName(self: MessageDescriptor, name: []const u8) ?*const Field {
        return self.fields_by_name.get(name);
    }
};

// Global registry of message types
var message_registry: std.StringArrayHashMap(*MessageDescriptor) = undefined;
var registry_allocator: std.mem.Allocator = undefined;

pub fn initRegistry(allocator: std.mem.Allocator) void {
    message_registry = std.StringArrayHashMap(*MessageDescriptor).init(allocator);
    registry_allocator = allocator;
}

pub fn deinitRegistry() void {
    var it = message_registry.iterator();
    while (it.next()) |entry| {
        entry.value_ptr.*.deinit();
        registry_allocator.destroy(entry.value_ptr.*);
    }
    message_registry.deinit();
}

pub fn registerMessage(descriptor: *MessageDescriptor) !void {
    try message_registry.put(descriptor.name, descriptor);
}

pub fn getMessage(name: []const u8) ?*MessageDescriptor {
    return message_registry.get(name);
}

// Field value union (for runtime type handling)
pub const FieldValue = union(enum) {
    int32: i32,
    int64: i64,
    sint32: i32,
    sint64: i64,
    uint32: u32,
    uint64: u64,
    bool: bool,
    @"enum": i32,
    fixed64: u64,
    sfixed64: i64,
    double: f64,
    string: []const u8,
    bytes: []const u8,
    fixed32: u32,
    sfixed32: i32,
    float: f32,
    message: *MessageInstance,
    repeated: *RepeatedValue,

    pub fn deinit(self: *FieldValue, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .string => |s| allocator.free(s),
            .bytes => |b| allocator.free(b),
            .message => |m| m.deinit(allocator),
            .repeated => |r| r.deinit(allocator),
            else => {},
        }
    }
};

// Message instance (runtime message object)
pub const MessageInstance = struct {
    descriptor: *const MessageDescriptor,
    values: std.AutoArrayHashMap(u32, FieldValue), // field index -> value
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, descriptor: *const MessageDescriptor) MessageInstance {
        return .{
            .descriptor = descriptor,
            .values = std.AutoArrayHashMap(u32, FieldValue).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *MessageInstance, allocator: std.mem.Allocator) void {
        var it = self.values.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit(allocator);
        }
        self.values.deinit();
    }

    pub fn setValue(self: *MessageInstance, field_index: u32, value: FieldValue) !void {
        // Clean up old value if it exists
        if (self.values.getPtr(field_index)) |old_value| {
            old_value.deinit(self.allocator);
        }

        try self.values.put(field_index, value);
    }

    pub fn getValue(self: MessageInstance, field_index: u32) ?FieldValue {
        return self.values.get(field_index);
    }
};

// Repeated field container
pub const RepeatedValue = struct {
    field_type: FieldType,
    values: std.ArrayList(FieldValue),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, field_type: FieldType) RepeatedValue {
        return .{
            .field_type = field_type,
            .values = std.ArrayList(FieldValue).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *RepeatedValue, allocator: std.mem.Allocator) void {
        for (self.values.items) |*value| {
            value.deinit(allocator);
        }
        self.values.deinit();
    }

    pub fn add(self: *RepeatedValue, value: FieldValue) !void {
        try self.values.append(value);
    }

    pub fn len(self: RepeatedValue) usize {
        return self.values.items.len;
    }

    pub fn get(self: RepeatedValue, index: usize) ?FieldValue {
        if (index < self.values.items.len) {
            return self.values.items[index];
        }
        return null;
    }
};