include "utils.pxi"
import inspect
#import traceback

wire_types = {
    'int32': 0,
    'int64': 0,
    'sint32': 0,
    'sint64': 0,
    'uint32': 0,
    'uint64': 0,
    'bool': 0,
    'enum': 0,
    'fixed64': 1,
    'sfixed64': 1,
    'double': 1,
    'string': 2,
    'bytes': 2,
    'fixed32': 5,
    'sfixed32': 5,
    'float': 5,
}

default_objects = {
    'int32': 0,
    'int64': 0,
    'sint32': 0,
    'sint64': 0,
    'uint32': 0,
    'uint64': 0,
    'bool': False,
    'enum': 0,
    'fixed64': 0,
    'sfixed64': 0,
    'double': 0.0,
    'string': u'',
    'bytes': '',
    'fixed32': 0,
    'sfixed32': 0,
    'float': 0.0,
}

cdef class RepeatedContainer(list):
    cdef object klass

    def __init__(self, cls):
        self.klass = cls

    def add(self, **kwargs):
        obj = self.klass(**kwargs)
        self.append(obj)
        return obj

cdef class Field(object):

    cdef public bytes name
    cdef object type
    cdef public int index
    cdef public bint packed
    cdef public bint required
    cdef public bint repeated
    cdef object klass
    cdef object default

    cdef public unsigned char wire_type
    cdef Encoder encoder
    cdef Decoder decoder

    def __init__(self, type, index, required=True, repeated=False, packed=False, default=None):
        assert type in wire_types or issubclass(type, ProtoEntity), 'invalid type %s' % type

        self.type = type
        self.index = index
        self.required = required
        self.repeated = repeated
        self.packed = packed

        if inspect.isclass(self.type) and issubclass(self.type, ProtoEntity):
            self.klass = self.type
        else:
            self.klass = None

        self.default = default or default_objects.get(self.type)

        self.wire_type = self.get_wire_type()
        self.encoder = self.get_encoder()
        self.decoder = self.get_decoder()

        if self.packed:
            assert self.repeated, 'packed must be used with repeated'

    def __get__(self, instance, type):
        if not instance:
            return self
        value = None
        if self.repeated:
            if self.klass:
                value = RepeatedContainer(self.klass)
            else:
                value = []
            setattr(instance, self.name, value)
        elif self.klass:
            value = self.klass()
            setattr(instance, self.name, value)
        else:
            value = self.default
        return value

    cdef unsigned char get_wire_type(self):
        if self.packed:
            return 2
        try:
            return wire_types[self.type]
        except KeyError:
            return 2

    cdef Encoder get_encoder(self):
        if self.type == 'int32':
            return encode_int64     # compatible with official protobuf
        if self.type == 'int64':
            return encode_int64
        if self.type == 'sint32':
            return encode_sint32
        if self.type == 'sint64':
            return encode_sint64
        if self.type == 'uint32':
            return encode_uint32
        if self.type == 'uint64':
            return encode_uint64
        if self.type == 'bool':
            return encode_bool
        if self.type == 'enum':
            return encode_int64     # compatible with official protobuf
        if self.type == 'fixed64':
            return encode_fixed64
        if self.type == 'sfixed64':
            return encode_sfixed64
        if self.type == 'fixed32':
            return encode_fixed32
        if self.type == 'sfixed32':
            return encode_sfixed32
        if self.type == 'string':
            return encode_string
        if self.type == 'bytes':
            return encode_bytes
        if self.type == 'float':
            return encode_float
        if self.type == 'double':
            return encode_double
        if issubclass(self.type, ProtoEntity):
            return encode_subobject
        return NULL

    cdef Decoder get_decoder(self):
        if self.type == 'int32':
            return decode_int64     # compatible with official protobuf
        if self.type == 'int64':
            return decode_int64
        if self.type == 'sint32':
            return decode_sint32
        if self.type == 'sint64':
            return decode_sint64
        if self.type == 'uint32':
            return decode_uint32
        if self.type == 'uint64':
            return decode_uint64
        if self.type == 'bool':
            return decode_bool
        if self.type == 'enum':
            return decode_int64     # compatible with official protobuf
        if self.type == 'fixed32':
            return decode_fixed32
        if self.type == 'fixed64':
            return decode_fixed64
        if self.type == 'sfixed32':
            return decode_sfixed32
        if self.type == 'sfixed64':
            return decode_sfixed64
        if self.type == 'string':
            return decode_string
        if self.type == 'bytes':
            return decode_bytes
        if self.type == 'float':
            return decode_float
        if self.type == 'double':
            return decode_double
        return NULL

class MetaProtoEntity(type):
    def __new__(cls, clsname, bases, attrs):
        if clsname == 'ProtoEntity':
            return super(MetaProtoEntity, cls).__new__(cls, clsname, bases, attrs)
        # _fields for encode
        # _fieldsmap for decode
        _fields = []
        _fieldsmap = {}
        _fieldsmap_by_name = {}
        cdef Field f
        for name, v in attrs.items():
            if name.startswith('__'):
                continue
            if not isinstance(v, Field):
                continue
            f = v
            f.name = name
            assert f.index not in _fieldsmap, 'duplicate field index %s' % f.index
            _fieldsmap[f.index] = f
            _fields.append(f)
            _fieldsmap_by_name[name] = f
        newcls = super(MetaProtoEntity, cls).__new__(cls, clsname, bases, attrs)
        newcls._fields = _fields
        newcls._fieldsmap = _fieldsmap
        newcls._fieldsmap_by_name = _fieldsmap_by_name
        return newcls

class ProtoEntity(object):
    __metaclass__ = MetaProtoEntity

    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)

    def SerializeToString(self):
        cdef bytearray buf = bytearray()
        encode_object(buf, self)
        return buf

    def ParseFromString(self, bytes s):
        cdef char *buff
        cdef char *start
        cdef char *end
        cdef Py_ssize_t size
        PyString_AsStringAndSize(s, &buff, &size)
        start = buff
        end = buff + size

        try:
            decode_object(self, &buff, end)
        except InternalDecodeError as e:
            #traceback.print_exc()
            raise DecodeError(e.args[0] - <uint64_t>start, e.args[1])

    def __unicode__(self):
        cdef Field f
        buf = []
        for f in self._fields:
            if not f.required:
                continue
            buf.append('%s = %s' % (f.name, getattr(self, f.name)))
        return '\n'.join(buf)

    def __str__(self):
        return unicode(self).encode('utf-8')

cdef inline encode_subobject(bytearray array, value):
    cdef bytearray sub_buf = bytearray()
    encode_object(sub_buf, value)
    encode_bytes(array, sub_buf)

cdef inline encode_object(bytearray buf, self):
    cdef bytearray buf1
    cdef dict d = self.__dict__
    cdef Field f
    for f in <list>self._fields:
        value = d.get(f.name)
        if value is None:
            continue
        if f.packed:
            encode_type(buf, f.wire_type, f.index)
            buf1 = bytearray()
            for item in <list?>value:
                f.encoder(buf1, item)
            encode_bytes(buf, buf1)
        else:
            if f.repeated:
                for item in <list?>value:
                    encode_type(buf, f.wire_type, f.index)
                    f.encoder(buf, item)
            else:
                encode_type(buf, f.wire_type, f.index)
                f.encoder(buf, value)

cdef inline int decode_object(object self, char **pointer, char *end) except -1:
    cdef dict fieldsmap = self._fieldsmap
    cdef uint32_t tag, wtype, findex

    cdef char *sub_buff
    cdef char *sub_end
    cdef uint64_t sub_size

    cdef Field f
    cdef dict d = self.__dict__
    cdef list l

    while pointer[0] < end:
        if raw_decode_uint32(pointer, end, &tag):
            raise makeDecodeError(pointer[0], "Can't deserialize type tag at [{0}] for value")
        findex = tag >> 3
        f = fieldsmap.get(findex)
        if f is None:
            wtype= tag & 0x07
            if skip_unknown_field(pointer, end, wtype):
                raise makeDecodeError(pointer[0], "Can't skip enough bytes for wire_type %s at [{0}] for value" % wtype)
        else:
            if f.packed:
                if raw_decode_delimited(pointer, end, &sub_buff, &sub_size):
                    raise makeDecodeError(pointer[0], "Can't decode value of type `packed` at [{0}]")
                sub_end = sub_buff + sub_size
                l = d.setdefault(f.name, [])
                while sub_buff < sub_end:
                    l.append(f.decoder(&sub_buff, sub_end))
            else:
                if f.klass is None:
                    value = f.decoder(pointer, end)
                else:
                    if raw_decode_delimited(pointer, end, &sub_buff, &sub_size):
                        raise makeDecodeError(pointer[0], "Can't decode value of sub message at [{0}]")
                    value = f.klass()
                    decode_object(value, &sub_buff, sub_buff+sub_size)
                if f.repeated:
                    l = d.setdefault(f.name, [])
                    l.append(value)
                else:
                    d[f.name] = value

    return 0
