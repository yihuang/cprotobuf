# cython hack http://stackoverflow.com/questions/13976504
from libc.stdint cimport *
import struct
STUFF = "Hi"

cdef extern from "Python.h":
    int PyString_AsStringAndSize(object obj, char **buffer, Py_ssize_t *length)
    object PyString_FromStringAndSize(const char *v, Py_ssize_t len)

ctypedef object (*Decoder)(bytes, int*)
ctypedef void (*Encoder)(object, list)

DEF kMaxVarintBytes = 10
DEF kMaxVarint32Bytes = 5

cdef inline uint64_t c_decode_varint(bytes s, int* pp):
    cdef uint64_t result = 0
    cdef int count = 0
    cdef uint8_t b
    cdef int p = pp[0]
    cdef Py_ssize_t l
    cdef char* c_s
    PyString_AsStringAndSize(s, &c_s, &l)

    while p < l:
        b = c_s[p]
        result |= <uint64_t>(b & 0x7F) << (7 * count)
        p += 1

        if b < 0x80:
            break

        count += 1
        if count == kMaxVarintBytes:
            raise Exception('too many bytes')

    pp[0] = p
    return result

cdef inline decode_varint(bytes s, int* p):
    return <int64_t>c_decode_varint(s, p)

cdef inline decode_uvarint(bytes s, int* p):
    return c_decode_varint(s, p)

cdef inline void c_encode_varint(uint64_t value, list buf):
    cdef uint8_t _buf[kMaxVarintBytes]
    cdef int size = 0
    while value > 0x7F:
        _buf[size] = (<uint8_t>(value) & 0x7F) | 0x80
        size += 1
        value >>= 7
    _buf[size] = <uint8_t>(value) & 0x7F
    buf.append(_buf[:size+1])

cdef inline void encode_varint(n, list buf):
    c_encode_varint(<int64_t>n, buf)

cdef inline void encode_uvarint(n, list buf):
    c_encode_varint(n, buf)

cdef inline int decode_tag(bytes s, int* p):
    return c_decode_varint(s, p)

cdef inline void encode_tag(int findex, int wtype, list buf):
    cdef int tag = (findex << 3) | wtype
    c_encode_varint(tag, buf)

cdef inline bytes decode_fixed(bytes s, int* pp, int n):
    cdef int p = pp[0]
    pp[0] = p+n
    return s[p:p+n]

cdef inline encode_fixed(bytes s, list buf):
    buf.append(s)

cdef inline decode_delimited(bytes s, int* p):
    cdef int l = c_decode_varint(s, p)
    return decode_fixed(s, p, l)

cdef inline void encode_delimited(s, list buf):
    c_encode_varint(len(<bytes>s), buf)
    buf.append(s)

cdef inline void encode_string(s, list buf):
    encode_delimited((<unicode>s).encode('utf-8'), buf)

cdef inline decode_string(bytes s, int* p):
    return (<bytes>decode_delimited(s, p)).decode('utf-8')

cdef inline int32_t from_zigzag32(uint32_t n):
    return (n >> 1) ^ (-<int32_t>(n & 1))

cdef inline uint32_t to_zigzag32(int32_t n):
    return (n << 1) ^ (n >> 31)

cdef inline int64_t from_zigzag64(uint64_t n):
    return (n >> 1) ^ (-<int64_t>(n & 1))

cdef inline uint64_t to_zigzag64(int64_t n):
    return (n << 1) ^ (n >> 63)

cdef inline decode_svarint32(bytes s, int* p):
    return from_zigzag32(c_decode_varint(s, p))

cdef inline void encode_svarint32(n, list buf):
    c_encode_varint(to_zigzag32(n), buf)

cdef inline decode_svarint64(bytes s, int* p):
    return from_zigzag64(c_decode_varint(s, p))

cdef inline void encode_svarint64(n, list buf):
    c_encode_varint(to_zigzag64(n), buf)

cdef inline int skip_varint(bytes s, int p):
    cdef char* c_s
    cdef Py_ssize_t c_l
    PyString_AsStringAndSize(s, &c_s, &c_l)
    while p < c_l and c_s[p] >= 0x80:
        p += 1
    return p + 1

cdef inline int skip_delimited(bytes s, int p):
    cdef int l = c_decode_varint(s, &p)
    return p + l

cdef inline int skip_unknown_field(bytes s, int p, int wtype):
    if wtype == 0:
        p = skip_varint(s, p)
    elif wtype == 1:
        p += 8
    elif wtype == 2:
        p = skip_delimited(s, p)
    elif wtype == 5:
        p += 4
    else:
        raise Exception('impossible')
    return p

cdef inline void encode_float(n, list buf):
    buf.append(struct.pack('<f', n))

cdef inline void encode_double(n, list buf):
    buf.append(struct.pack('<d', n))

cdef inline decode_float(bytes s, int* pp):
    cdef int p = pp[0]
    pp[0] += 4
    return struct.unpack('<f', s[p:p+4])[0]

cdef inline decode_double(bytes s, int* pp):
    cdef int p = pp[0]
    pp[0] += 8
    return struct.unpack('<d', s[p:p+8])[0]

cdef inline void encode_fixed64(n, list buf):
    buf.append(struct.pack('<q', n))

cdef inline void encode_fixed32(n, list buf):
    buf.append(struct.pack('<i', n))

cdef inline void encode_sfixed64(n, list buf):
    buf.append(struct.pack('<Q', to_zigzag64(n)))

cdef inline void encode_sfixed32(n, list buf):
    buf.append(struct.pack('<I', to_zigzag32(n)))

cdef inline decode_fixed64(bytes s, int* pp):
    cdef int p = pp[0]
    pp[0] += 8
    return struct.unpack('<q', s[p:p+8])[0]

cdef inline decode_fixed32(bytes s, int* pp):
    cdef int p = pp[0]
    pp[0] += 4
    return struct.unpack('<i', s[p:p+4])[0]

cdef inline decode_sfixed64(bytes s, int* pp):
    return from_zigzag64(decode_fixed64(s, pp))

cdef inline decode_sfixed32(bytes s, int* pp):
    return from_zigzag32(decode_fixed32(s, pp))

cdef inline void encode_submessage(v, list buf):
    encode_delimited(v.SerializeToString(), buf)

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

    cdef public int wire_type
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

    cdef int get_wire_type(self):
        if self.pack:
            return 2
        try:
            return wire_types[self.type]
        except KeyError:
            assert issubclass(self.type, ProtoEntity)
            return 2

    cdef Encoder get_encoder(self):
        if self.type == 'int32':
            return encode_varint
        if self.type == 'int64':
            return encode_varint
        if self.type == 'sint32':
            return encode_svarint32
        if self.type == 'sint64':
            return encode_svarint32
        if self.type == 'uint32':
            return encode_uvarint
        if self.type == 'uint64':
            return encode_uvarint
        if self.type == 'bool':
            return encode_varint
        if self.type == 'enum':
            return encode_varint
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
            return encode_delimited
        if self.type == 'float':
            return encode_float
        if self.type == 'double':
            return encode_double
        if issubclass(self.type, ProtoEntity):
            return encode_submessage
        raise Exception('unsupported field type')

    cdef Decoder get_decoder(self):
        if self.type == 'int32':
            return decode_varint
        if self.type == 'int64':
            return decode_varint
        if self.type == 'sint32':
            return decode_svarint32
        if self.type == 'sint64':
            return decode_svarint64
        if self.type == 'uint32':
            return decode_uvarint
        if self.type == 'uint64':
            return decode_uvarint
        if self.type == 'bool':
            return decode_varint
        if self.type == 'enum':
            return decode_varint
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
            return decode_delimited
        if self.type == 'float':
            return decode_float
        if self.type == 'double':
            return decode_double
        if issubclass(self.type, ProtoEntity):
            return decode_delimited
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
        cdef list buf = []
        cdef list buf1
        cdef dict d = self.__dict__
        cdef Field f
        for f in <list>self._fields:
            value = d.get(f.name)
            if value is None:
                continue
            if f.pack:
                encode_tag(f.index, f.wire_type, buf)
                buf1 = []
                for item in <list>value:
                    f.encoder(item, buf1)
                encode_delimited(''.join(buf1), buf)
            else:
                if f.repeated:
                    for item in <list>value:
                        encode_tag(f.index, f.wire_type, buf)
                        f.encoder(item, buf)
                else:
                    encode_tag(f.index, f.wire_type, buf)
                    f.encoder(value, buf)
        return ''.join(buf)

    def ParseFromString(self, bytes s):
        cdef dict fieldsmap = self._fieldsmap
        cdef int p = 0
        cdef int tag, wtype, findex
        cdef int s_l = len(s)
        cdef int subp = 0
        cdef bytes subs
        cdef int sublen = 0
        cdef Field f
        cdef dict d = self.__dict__
        while p < s_l - 1:
            tag = decode_tag(s, &p)
            findex = tag >> 3
            f = fieldsmap.get(findex)
            if f is None:
                wtype= tag & 0x07
                p = skip_unknown_field(s, p, wtype)
            else:
                if f.pack:
                    subs = decode_delimited(s, &p)
                    sublen = len(subs)
                    subp = 0
                    d.setdefault(f.name, [])
                    while subp < sublen:
                        value = f.decoder(subs, &subp)
                        d[f.name].append(value)
                else:
                    value = f.decoder(s, &p)
                    if not isinstance(f.type, str):
                        subs = value
                        value = f.type()
                        value.ParseFromString(subs)
                    if f.repeated:
                        d.setdefault(f.name, [])
                        d[f.name].append(value)
                    else:
                        d[f.name] = value

    def __unicode__(self):
        cdef Field f
        buf = []
        for f in self._fields:
            buf.append('%s = %s' % (f.name, getattr(self, f.name)))
        return '\n'.join(buf)

    def __str__(self):
        return unicode(self).encode('utf-8')

if __name__ == '__main__':
    import doctest
    doctest.testmod()
