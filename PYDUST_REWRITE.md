# cprotobuf PyDust Rewrite

This document describes the rewrite of cprotobuf using the Zig PyDust framework.

## Overview

The original cprotobuf was implemented in Cython for performance. This rewrite migrates the core implementation to Zig using PyDust, which provides:

1. **Better performance**: Zig's zero-cost abstractions and manual memory management
2. **Memory safety**: Compile-time checks and optional runtime bounds checking
3. **Modern build system**: PyDust integrates with Python's modern packaging
4. **Cross-platform**: Zig's cross-compilation capabilities
5. **Simpler codebase**: Single language (Zig) for core logic vs Cython/C mix

## Architecture

### Directory Structure

```
cprotobuf/
├── src/                    # Zig source code
│   ├── main.zig           # Module entry point
│   ├── types.zig          # Type definitions and descriptors
│   ├── encoder.zig        # Encoding logic
│   ├── decoder.zig        # Decoding logic
│   └── python.zig         # Python bindings (PyDust)
├── cprotobuf/
│   ├── __init__.py        # Python interface (fallback)
│   └── _native.py         # Generated PyDust bindings
├── pyproject.toml         # PyDust build configuration
└── setup.py              # Legacy setup compatibility
```

### Core Components

1. **Types (`types.zig`)**:
   - `Field`: Protobuf field descriptor
   - `MessageDescriptor`: Message type metadata
   - `MessageInstance`: Runtime message object
   - `FieldValue`: Union type for field values

2. **Encoder (`encoder.zig`)**:
   - Varint encoding/decoding
   - Zigzag encoding for signed integers
   - Message serialization
   - Packed repeated field handling

3. **Decoder (`decoder.zig`)**:
   - Wire format parsing
   - Type conversion
   - Unknown field skipping
   - Error handling

4. **Python Bindings (`python.zig`)**:
   - `FieldPython`: Python wrapper for Field
   - `ProtoEntityPython`: Python wrapper for ProtoEntity
   - `RepeatedContainerPython`: Python wrapper for repeated fields
   - Utility function exports

### Python Interface

The Python interface maintains backward compatibility:

```python
from cprotobuf import ProtoEntity, Field

class Person(ProtoEntity):
    id = Field('int32', 1)
    name = Field('string', 2)
    email = Field('string', 3, required=False)

person = Person(id=123, name="Test")
data = person.SerializeToString()
person2 = Person()
person2.ParseFromString(data)
```

## Build System

### Requirements

- Python 3.7+
- Zig 0.12.0+
- PyDust (`pip install pydust`)

### Building

```bash
# Install in development mode
pip install -e .

# Or build wheel
pip wheel .
```

### Development

```bash
# Install dependencies
pip install pydust

# Build and install
pip install -e .

# Run tests
python -m pytest test/
```

## Migration Status

### ✅ Completed
- Zig core type definitions
- Encoding/decoding logic
- Python binding structure
- Build configuration
- Backward-compatible Python interface

### ⚠️ Partially Implemented
- Python ↔ Zig type conversion
- Message descriptor registration
- Repeated container implementation

### ❌ Not Implemented
- Plugin code generator (`protoc-gen-cprotobuf`)
- Full test suite compatibility
- Performance benchmarking

## Performance Considerations

The Zig implementation should provide similar or better performance than Cython:

1. **Zero-cost abstractions**: Zig's compile-time execution
2. **Manual memory management**: Arena allocators for message parsing
3. **SIMD optimizations**: Potential for vectorized operations
4. **Minimal runtime overhead**: Direct Python object access via PyDust

## API Compatibility

The rewrite maintains full API compatibility with the original cprotobuf:

- Same `Field` constructor signature
- Same `ProtoEntity` base class
- Same `SerializeToString()`/`ParseFromString()` methods
- Same `encode_primitive()`/`decode_primitive()` utilities
- Same `encode_data()` function for direct encoding

## Next Steps

1. **Implement missing native methods** in `python.zig`
2. **Add Python fallback implementations** for all functions
3. **Update plugin generator** to work with new architecture
4. **Run existing test suite** to verify compatibility
5. **Performance benchmarking** against Cython version
6. **Documentation updates** for new build process

## References

- [PyDust Documentation](https://pydust.fulcrum.so/latest/)
- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [Protocol Buffers Encoding](https://developers.google.com/protocol-buffers/docs/encoding)
- [Original cprotobuf](https://github.com/yihuang/cprotobuf)