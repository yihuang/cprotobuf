# Try to import from native Zig module first
try:
    from ._native import (Field, ProtoEntity, decode_primitive,
                         encode_data, encode_primitive, get_proto,
                         register_proto)
    HAS_NATIVE = True
except ImportError:
    # Fall back to Python implementation
    HAS_NATIVE = False

    # Python implementation of core classes
    class Field:
        """Python implementation of Field (fallback)."""
        def __init__(self, type, index, required=True, repeated=False, packed=False, default=None):
            self.type = type
            self.index = index
            self.required = required
            self.repeated = repeated
            self.packed = packed
            self.default = default
            self.name = None  # Set by metaclass

        def __get__(self, instance, owner):
            if instance is None:
                return self

            # Create default value
            if self.repeated:
                value = []
                setattr(instance, self.name, value)
                return value
            elif hasattr(self.type, '__call__'):  # Message type
                value = self.type()
                setattr(instance, self.name, value)
                return value
            else:
                return self.default

    class MetaProtoEntity(type):
        """Metaclass for ProtoEntity classes."""
        def __new__(cls, name, bases, attrs):
            if name == 'ProtoEntity':
                return super().__new__(cls, name, bases, attrs)

            # Collect fields
            fields = []
            fieldsmap = {}
            fieldsmap_by_name = {}

            for attr_name, attr_value in attrs.items():
                if attr_name.startswith('__'):
                    continue
                if not isinstance(attr_value, Field):
                    continue

                field = attr_value
                field.name = attr_name
                fieldsmap[field.index] = field
                fields.append(field)
                fieldsmap_by_name[attr_name] = field

            # Sort fields by index
            fields.sort(key=lambda f: f.index)

            # Create class
            new_cls = super().__new__(cls, name, bases, attrs)
            new_cls._fields = fields
            new_cls._fieldsmap = fieldsmap
            new_cls._fieldsmap_by_name = fieldsmap_by_name

            # Register proto
            register_proto(name, new_cls)

            return new_cls

    class ProtoEntity(metaclass=MetaProtoEntity):
        """Base class for protocol buffer messages."""
        def __init__(self, **kwargs):
            self.__dict__.update(kwargs)

        def SerializeToString(self):
            """Serialize message to bytes."""
            if HAS_NATIVE:
                return encode_data(type(self), self.__dict__)
            else:
                # Python fallback implementation
                raise NotImplementedError("Python fallback not implemented")

        def ParseFromString(self, s, offset=0, count=-1):
            """Parse message from bytes."""
            if HAS_NATIVE:
                # Call native implementation
                pass  # Will be implemented in native module
            else:
                # Python fallback implementation
                raise NotImplementedError("Python fallback not implemented")

        def todict(self):
            """Convert message to dictionary."""
            data = {}
            for field in self._fields:
                value = getattr(self, field.name, None)
                if value is None:
                    continue

                if field.repeated:
                    if len(value) == 0:
                        continue
                    if hasattr(value[0], 'todict'):
                        data[field.name] = [v.todict() for v in value]
                    else:
                        data[field.name] = value
                else:
                    if hasattr(value, 'todict'):
                        data[field.name] = value.todict()
                    else:
                        data[field.name] = value
            return data

        def __str__(self):
            return str(self.todict())

    # Fallback implementations of utility functions
    def decode_primitive(s, tp):
        if HAS_NATIVE:
            return _native.decode_primitive(s, tp)
        else:
            raise NotImplementedError("Python fallback not implemented")

    def encode_primitive(tp, v):
        if HAS_NATIVE:
            return _native.encode_primitive(tp, v)
        else:
            raise NotImplementedError("Python fallback not implemented")

    def encode_data(cls, d):
        if HAS_NATIVE:
            return _native.encode_data(cls, d)
        else:
            raise NotImplementedError("Python fallback not implemented")

    def get_proto(name):
        if HAS_NATIVE:
            return _native.get_proto(name)
        else:
            raise NotImplementedError("Python fallback not implemented")

    def register_proto(name, cls):
        if HAS_NATIVE:
            return _native.register_proto(name, cls)
        else:
            raise NotImplementedError("Python fallback not implemented")

__version__ = "0.1.12"  # Bump version for PyDust rewrite
