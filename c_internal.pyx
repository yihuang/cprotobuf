# cython hack http://stackoverflow.com/questions/13976504
STUFF = "Hi"

cdef extern from "Python.h":
    int PyString_AsStringAndSize(object obj, char **buffer, Py_ssize_t *length)
    object PyString_FromStringAndSize(const char *v, Py_ssize_t len)

ctypedef object (*Decoder)(bytes, int*)
ctypedef void (*Encoder)(object, list)

cdef inline int c_decode_varint(bytes s, int* pp):
    cdef int r = 0
    cdef int shift = 0
    cdef char* c_s
    cdef Py_ssize_t c_l
    PyString_AsStringAndSize(s, &c_s, &c_l)
    cdef char b
    cdef int p = pp[0]
    while p < c_l:
        b = c_s[p]
        r |= ((b & 0x7f) << shift)
        p += 1
        if not b & 0x80:
            break
        shift += 7
        if shift >= 64:
            raise Exception('too many bytes')

    pp[0] = p
    return r

cdef inline decode_varint(bytes s, int* p):
    return c_decode_varint(s, p)

cdef inline c_chr(char n):
    return PyString_FromStringAndSize(&n, 1)

cdef inline void c_encode_varint(int n, list buf):
    cdef int b = n & 0x7f
    n >>= 7
    while n:
        buf.append(c_chr(0x80|b))
        b = n & 0x7f
        n >>= 7
    buf.append(c_chr(b))

cdef inline void encode_varint(n, list buf):
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
    encode_delimited(s.encode('utf-8'), buf)

cdef inline decode_string(bytes s, int* p):
    return (<bytes>decode_delimited(s, p)).decode('utf-8')

cdef inline int from_zigzag(int n):
    if not n & 0x1:
        return n >> 1
    return (n >> 1) ^ (~0)

cdef inline int to_zigzag(int n):
    if n >= 0:
        return n << 1
    return (n << 1) ^ (~0)

cdef inline decode_svarint(bytes s, int* p):
    return from_zigzag(c_decode_varint(s, p))

cdef inline void encode_svarint(n, list buf):
    c_encode_varint(to_zigzag(n), buf)

cdef inline int skip_varint(bytes s, int p):
    cdef char* c_s
    cdef Py_ssize_t c_l
    PyString_AsStringAndSize(s, &c_s, &c_l)
    while p < c_l and c_s[p] & 0x80:
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

    cdef bytes name
    cdef bytes type
    cdef int index
    cdef bint pack
    cdef bint required
    cdef bint repeated
    cdef object default

    cdef int wire_type
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
            assert isinstance(self.type, ProtoEntity)
            return 2

    cdef Encoder get_encoder(self):
        if self.type == 'int32':
            return encode_varint
        if self.type == 'int64':
            return encode_varint
        if self.type == 'sint32':
            return encode_svarint
        if self.type == 'sint64':
            return encode_svarint
        #if self.type == 'uint32':
        #    return encode_uint32
        #if self.type == 'uint64':
        #    return encode_uint64
        if self.type == 'bool':
            return encode_varint
        if self.type == 'enum':
            return encode_varint
        #if self.type == 'fixed64':
        #    return encode_fixed64
        #if self.type == 'sfixed64':
        #    return encode_sfixed64
        #if self.type == 'double':
        #    return encode_double
        if self.type == 'string':
            return encode_string
        if self.type == 'bytes':
            return encode_delimited
        #if self.type == 'fixed32':
        #    return encode_fixed32
        #if self.type == 'sfixed32':
        #    return encode_sfixed32
        #if self.type == 'float':
        #    return encode_float

    cdef Decoder get_decoder(self):
        if self.type == 'int32':
            return decode_varint
        if self.type == 'int64':
            return decode_varint
        if self.type == 'sint32':
            return decode_svarint
        if self.type == 'sint64':
            return decode_svarint
        #if self.type == 'uint32':
        #    return decode_uint32
        #if self.type == 'uint64':
        #    return decode_uint64
        if self.type == 'bool':
            return decode_varint
        if self.type == 'enum':
            return decode_varint
        #if self.type == 'fixed64':
        #    return decode_fixed64
        #if self.type == 'sfixed64':
        #    return decode_sfixed64
        #if self.type == 'double':
        #    return decode_double
        if self.type == 'string':
            return decode_string
        if self.type == 'bytes':
            return decode_delimited
        #if self.type == 'fixed32':
        #    return decode_fixed32
        #if self.type == 'sfixed32':
        #    return decode_sfixed32
        #if self.type == 'float':
        #    return decode_float

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
        buf = []
        d = self.__dict__
        cdef Field f
        for f in self._fields:
            value = d[f.name]
            if f.pack:
                encode_tag(f.index, f.wire_type, buf)
                buf1 = []
                for item in value:
                    f.encoder(item, buf1)
                encode_delimited(''.join(buf1), buf)
            else:
                if f.repeated:
                    for item in value:
                        encode_tag(f.index, f.wire_type, buf)
                        f.encoder(item, buf)
                else:
                    encode_tag(f.index, f.wire_type, buf)
                    f.encoder(value, buf)
        return ''.join(buf)

    def ParseFromString(self, s):
        fieldsmap = self._fieldsmap
        cdef int p = 0
        cdef int tag, wtype, findex
        cdef int s_l = len(s)
        cdef int subp = 0
        cdef bytes subs
        cdef int sublen = 0
        cdef Field f
        d = self.__dict__
        while p < s_l - 1:
            tag = decode_tag(s, &p)
            findex = tag >> 3
            try:
                f = fieldsmap[findex]
            except KeyError:
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
                    if f.repeated:
                        d.setdefault(f.name, [])
                        d[f.name].append(value)
                    else:
                        d[f.name] = value

if __name__ == '__main__':
    import doctest
    doctest.testmod()
