const std = @import("std");
const py = @import("pydust");
const types = @import("types.zig");
const encoder = @import("encoder.zig");
const decoder = @import("decoder.zig");

// Python wrapper for Field
pub const FieldPython = py.class(struct {
    const Self = @This();

    // Python attributes
    name: []const u8,
    type: py.PyObject, // Can be string or class
    index: i32,
    required: bool = true,
    repeated: bool = false,
    is_packed: bool = false,
    default: ?py.PyObject = null,

    // Internal field descriptor
    field: ?*types.Field = null,

    pub fn __init__(self: *Self, args: struct {
        type: py.PyObject,
        index: i32,
        required: bool = true,
        repeated: bool = false,
        is_packed: bool = false,
        default: ?py.PyObject = null,
    }) !void {
        self.type = args.type;
        self.index = args.index;
        self.required = args.required;
        self.repeated = args.repeated;
        self.is_packed = args.is_packed;
        self.default = args.default;

        // Name will be set by metaclass
        self.name = "";

        // Create internal field descriptor
        self.field = try createFieldDescriptor(self);
    }

    fn createFieldDescriptor(self: *Self) !*types.Field {
        const allocator = std.heap.page_allocator;

        // Determine field type
        const field_type = try determineFieldType(self.type);

        // Create field
        const field = try allocator.create(types.Field);
        field.* = .{
            .name = self.name,
            .field_type = field_type,
            .index = @as(u32, @intCast(self.index)),
            .required = self.required,
            .repeated = self.repeated,
            .is_packed = self.is_packed,
            .default = null, // TODO: Handle defaults
            .message_type = if (field_type == .message) getMessageTypeName(self.type) else null,
        };

        return field;
    }

    fn determineFieldType(type_obj: py.PyObject) !types.FieldType {
        if (py.PyUnicode_Check(type_obj)) {
            const type_str = try py.PyUnicode_AsUTF8(type_obj);
            return stringToFieldType(type_str);
        } else if (py.PyType_Check(type_obj)) {
            // It's a message class
            return .message;
        } else {
            return error.InvalidFieldType;
        }
    }

    fn stringToFieldType(str: []const u8) types.FieldType {
        const map = std.ComptimeStringMap(types.FieldType, .{
            .{ "int32", .int32 },
            .{ "int64", .int64 },
            .{ "sint32", .sint32 },
            .{ "sint64", .sint64 },
            .{ "uint32", .uint32 },
            .{ "uint64", .uint64 },
            .{ "bool", .bool },
            .{ "enum", .@"enum" },
            .{ "fixed64", .fixed64 },
            .{ "sfixed64", .sfixed64 },
            .{ "double", .double },
            .{ "string", .string },
            .{ "bytes", .bytes },
            .{ "fixed32", .fixed32 },
            .{ "sfixed32", .sfixed32 },
            .{ "float", .float },
        });

        return map.get(str) orelse .message; // Assume message type if not found
    }

    fn getMessageTypeName(type_obj: py.PyObject) ?[]const u8 {
        // TODO: Extract message type name from class
        _ = type_obj;
        return null;
    }

    pub fn __dealloc__(self: *Self) void {
        if (self.field) |f| {
            std.heap.page_allocator.destroy(f);
        }
    }
});

// Python wrapper for ProtoEntity
pub const ProtoEntityPython = py.class(struct {
    const Self = @This();

    // Python attributes
    _fields: []const FieldPython,
    _fieldsmap: std.AutoArrayHashMap(i32, *FieldPython),
    _fieldsmap_by_name: std.StringArrayHashMap(*FieldPython),

    // Internal message descriptor
    descriptor: ?*types.MessageDescriptor = null,

    pub fn __init__(self: *Self, kwargs: py.PyObject) !void {
        // kwargs parameter is required by PyDust interface
        // but we don't use it directly - metaclass handles initialization
        _ = kwargs;
        @compileLog("ProtoEntityPython.__init__ called");
    }

    pub fn SerializeToString(self: *Self) !py.PyObject {
        const allocator = std.heap.page_allocator;

        // Convert Python object to MessageInstance
        const message_instance = try self.toMessageInstance(allocator);
        defer message_instance.deinit(allocator);

        // Encode message
        const encoded = try encoder.encodeMessageData(allocator, &message_instance);
        defer allocator.free(encoded);

        // Return as Python bytes
        return py.PyBytes_FromStringAndSize(encoded.ptr, encoded.len);
    }

    pub fn ParseFromString(self: *Self, args: struct {
        s: []const u8,
        offset: i32 = 0,
        count: i32 = -1,
    }) !void {
        const allocator = std.heap.page_allocator;

        // Validate bounds
        if (args.offset < 0 or args.offset >= args.s.len) {
            return error.OffsetOutOfBounds;
        }

        const end = if (args.count < 0)
            args.s.len
        else
            @min(args.offset + args.count, args.s.len);

        const data = args.s[args.offset..end];

        // Decode message
        if (self.descriptor) |desc| {
            const message_instance = try decoder.decodeMessageData(allocator, data, desc);
            defer message_instance.deinit(allocator);

            // Update Python object from message instance
            try self.fromMessageInstance(&message_instance);
        } else {
            return error.NoDescriptor;
        }
    }

    fn toMessageInstance(self: *Self, allocator: std.mem.Allocator) !types.MessageInstance {
        // TODO: Implement conversion from Python object to MessageInstance
        _ = self;
        _ = allocator;
        return error.NotImplemented;
    }

    fn fromMessageInstance(self: *Self, instance: *types.MessageInstance) !void {
        // TODO: Implement conversion from MessageInstance to Python object
        _ = self;
        _ = instance;
        return error.NotImplemented;
    }

    pub fn todict(self: *Self) !py.PyObject {
        // TODO: Implement todict method
        _ = self;
        return py.PyDict_New();
    }
});

// Python wrapper for RepeatedContainer
pub const RepeatedContainerPython = py.class(struct {
    const Self = @This();

    klass: py.PyObject,
    items: std.ArrayList(py.PyObject),

    pub fn __init__(self: *Self, args: struct { klass: py.PyObject }) !void {
        self.klass = args.klass;
        self.items = std.ArrayList(py.PyObject).init(std.heap.page_allocator);
    }

    pub fn __dealloc__(self: *Self) void {
        self.items.deinit();
    }

    pub fn add(self: *Self, kwargs: py.PyObject) !py.PyObject {
        // Create new instance of klass with kwargs
        const obj = try py.PyObject_Call(self.klass, py.PyTuple_New(0), kwargs);
        try self.items.append(obj);
        return obj;
    }

    pub fn append(self: *Self, args: struct { item: py.PyObject }) !void {
        try self.items.append(args.item);
    }

    pub fn __len__(self: *Self) i64 {
        return @as(i64, @intCast(self.items.items.len));
    }

    pub fn __getitem__(self: *Self, args: struct { index: i64 }) !py.PyObject {
        const idx = @as(usize, @intCast(args.index));
        if (idx >= self.items.items.len) {
            return error.IndexError;
        }
        return self.items.items[idx];
    }

    pub fn __setitem__(self: *Self, args: struct { index: i64, value: py.PyObject }) !void {
        const idx = @as(usize, @intCast(args.index));
        if (idx >= self.items.items.len) {
            return error.IndexError;
        }
        self.items.items[idx] = args.value;
    }
});

// Python utility functions
pub fn encode_primitive_py(args: struct { tp: []const u8, v: py.PyObject }) !py.PyObject {
    const allocator = std.heap.page_allocator;

    // Convert Python value to FieldValue
    const field_type = FieldPython.stringToFieldType(args.tp);
    const field_value = try pythonToFieldValue(allocator, args.v, field_type);
    defer field_value.deinit(allocator);

    // Encode primitive
    const encoded = try encoder.encodePrimitive(allocator, field_type, field_value);
    defer allocator.free(encoded);

    return py.PyBytes_FromStringAndSize(encoded.ptr, encoded.len);
}

pub fn decode_primitive_py(args: struct { s: []const u8, tp: []const u8 }) !py.PyObject {
    const allocator = std.heap.page_allocator;

    const field_type = FieldPython.stringToFieldType(args.tp);
    const result = try decoder.decodePrimitive(allocator, args.s, field_type);
    defer result.value.deinit(allocator);

    return fieldValueToPython(result.value);
}

pub fn encode_data_py(args: struct { cls: py.PyObject, d: py.PyObject }) !py.PyObject {
    // TODO: Implement encode_data
    _ = args;
    return error.NotImplemented;
}

pub fn get_proto_py(args: struct { name: []const u8 }) !py.PyObject {
    if (types.getMessage(args.name)) |descriptor| {
        // TODO: Return Python class for this descriptor
        _ = descriptor;
        return error.NotImplemented;
    } else {
        return py.PyErr_Format(py.PyExc_KeyError, "No such proto: %s", args.name);
    }
}

pub fn register_proto_py(args: struct { name: []const u8, cls: py.PyObject }) !void {
    // TODO: Register Python class as a proto type
    _ = args;
}

// Conversion utilities
fn pythonToFieldValue(allocator: std.mem.Allocator, obj: py.PyObject, field_type: types.FieldType) !types.FieldValue {
    return switch (field_type) {
        .int32 => types.FieldValue{ .int32 = try py.PyLong_AsLong(obj) },
        .int64 => types.FieldValue{ .int64 = try py.PyLong_AsLongLong(obj) },
        .uint32 => types.FieldValue{ .uint32 = @as(u32, @intCast(try py.PyLong_AsUnsignedLong(obj))) },
        .uint64 => types.FieldValue{ .uint64 = try py.PyLong_AsUnsignedLongLong(obj) },
        .bool => types.FieldValue{ .bool = py.PyObject_IsTrue(obj) },
        .float => types.FieldValue{ .float = @as(f32, @floatCast(try py.PyFloat_AsDouble(obj))) },
        .double => types.FieldValue{ .double = try py.PyFloat_AsDouble(obj) },
        .string => {
            const str = try py.PyUnicode_AsUTF8(obj);
            const copy = try allocator.alloc(u8, str.len);
            @memcpy(copy, str);
            return types.FieldValue{ .string = copy };
        },
        .bytes => {
            const buffer = try py.PyBytes_AsString(obj);
            const copy = try allocator.alloc(u8, buffer.len);
            @memcpy(copy, buffer);
            return types.FieldValue{ .bytes = copy };
        },
        else => return error.UnsupportedConversion,
    };
}

fn fieldValueToPython(value: types.FieldValue) !py.PyObject {
    return switch (value) {
        .int32 => |v| py.PyLong_FromLong(v),
        .int64 => |v| py.PyLong_FromLongLong(v),
        .uint32 => |v| py.PyLong_FromUnsignedLong(v),
        .uint64 => |v| py.PyLong_FromUnsignedLongLong(v),
        .bool => |v| if (v) py.Py_True else py.Py_False,
        .float => |v| py.PyFloat_FromDouble(v),
        .double => |v| py.PyFloat_FromDouble(v),
        .string => |v| py.PyUnicode_FromStringAndSize(v.ptr, v.len),
        .bytes => |v| py.PyBytes_FromStringAndSize(v.ptr, v.len),
        else => return error.UnsupportedConversion,
    };
}