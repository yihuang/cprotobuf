include "utils.pxi"
import traceback

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

cdef class Field(object):

    cdef public bytes name
    cdef object type
    cdef public int index
    cdef public bint pack
    cdef public bint required
    cdef public bint repeated
    cdef object default

    cdef public unsigned char wire_type
    cdef Encoder encoder
    cdef Decoder decoder

    def __init__(self, type, index, required=True, repeated=False, pack=False, default=None):
        self.type = type
        self.index = index
        self.required = required
        self.repeated = repeated
        self.pack = pack
        self.default = default

        self.wire_type = self.get_wire_type()
        self.encoder = self.get_encoder()
        self.decoder = self.get_decoder()

        if self.pack:
            assert self.repeated, 'pack must be used with repeated'

    cdef unsigned char get_wire_type(self):
        if self.pack:
            return 2
        try:
            return wire_types[self.type]
        except KeyError:
            #assert issubclass(self.type, ProtoEntity)
            return 2

    cdef Encoder get_encoder(self) except NULL:
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
            return encode_uint32
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
        #if issubclass(self.type, ProtoEntity):
        #    return encode_submessage
        raise Exception('unsupported field type')

    cdef Decoder get_decoder(self) except NULL:
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
            return decode_uint32
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
        #if issubclass(self.type, ProtoEntity):
        #    return decode_bytes
        raise Exception('unsupported field type')

class MetaProtoEntity(type):
    def __new__(cls, clsname, bases, attrs):
        if clsname == 'ProtoEntity':
            return super(MetaProtoEntity, cls).__new__(cls, clsname, bases, attrs)
        # _fields for encode
        # _fieldsmap for decode
        _fields = []
        _fieldsmap = {}
        cdef Field f
        for name, v in attrs.items():
            if not isinstance(v, Field):
                continue
            if name.startswith('__'):
                continue
            f = v
            f.name = name
            _fields.append(f)
            _fieldsmap[f.index] = f
        newcls = super(MetaProtoEntity, cls).__new__(cls, clsname, bases, attrs)
        newcls._fields = _fields
        newcls._fieldsmap = _fieldsmap
        return newcls

class ProtoEntity(object):
    __metaclass__ = MetaProtoEntity

    def __init__(self, **kwargs):
        for k,v in kwargs.items():
            setattr(self, k, v)

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
            traceback.print_exc()
            raise DecodeError(e.args[0] - <uint64_t>start, e.args[1])

    def __unicode__(self):
        cdef Field f
        buf = []
        for f in self._fields:
            buf.append('%s = %s' % (f.name, getattr(self, f.name)))
        return '\n'.join(buf)

    def __str__(self):
        return unicode(self).encode('utf-8')

cdef inline int encode_object(bytearray buf, self) except -1:
    cdef bytearray buf1
    cdef dict d = self.__dict__
    cdef Field f
    for f in <list>self._fields:
        value = d.get(f.name)
        if value is None:
            continue
        if f.pack:
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
    return 0

cdef inline int decode_object(object self, char **pointer, char *end) except -1:
    cdef dict fieldsmap = self._fieldsmap
    cdef uint32_t tag, wtype, findex

    cdef char *sub_buff
    cdef char *sub_end
    cdef uint64_t sub_size

    cdef Field f
    cdef dict d = self.__dict__

    while pointer[0] < end:
        if raw_decode_uint32(pointer, end, &tag):
            raise makeDecodeError(pointer[0], "Can't deserialize type tag at [{0}] for value")
        findex = tag >> 3
        f = fieldsmap.get(findex)
        if f is None:
            wtype= tag & 0x07
            if skip_unknown_field(pointer, end, wtype):
                raise makeDecodeError(pointer[0], "Can't skip enough bytes at [{0}] for value")
        else:
            if f.pack:
                if raw_decode_delimited(pointer, end, &sub_buff, &sub_size):
                    raise makeDecodeError(pointer[0], "Can't decode value of type `packed` at [{0}]")
                sub_end = sub_buff + sub_size
                d.setdefault(f.name, [])
                while sub_buff < sub_end:
                    value = f.decoder(&sub_buff, sub_end)
                    d[f.name].append(value)
            else:
                value = f.decoder(pointer, end)
                if f.repeated:
                    d.setdefault(f.name, [])
                    d[f.name].append(value)
                else:
                    d[f.name] = value

    return 0
