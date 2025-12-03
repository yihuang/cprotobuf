const std = @import("std");
const py = @import("pydust");

// Import modules
const types = @import("types.zig");
const encoder = @import("encoder.zig");
const decoder = @import("decoder.zig");
const python = @import("python.zig");

// Module initialization
pub fn module_init() void {
    // Initialize PyDust module
    py.module.init("_cprotobuf_native");

    // Register Python classes
    python.FieldPython.register();
    python.ProtoEntityPython.register();
    python.RepeatedContainerPython.register();

    // Register functions
    py.module.addFunction("encode_primitive", python.encode_primitive_py);
    py.module.addFunction("decode_primitive", python.decode_primitive_py);
    py.module.addFunction("encode_data", python.encode_data_py);
    py.module.addFunction("get_proto", python.get_proto_py);
    py.module.addFunction("register_proto", python.register_proto_py);
}

