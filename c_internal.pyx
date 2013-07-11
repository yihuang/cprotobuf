# cython hack http://stackoverflow.com/questions/13976504
STUFF = "Hi"

cdef extern from "Python.h":
    int PyString_AsStringAndSize(object obj, char **buffer, int *length)
    object PyString_FromStringAndSize(const char *v, int len)

cdef inline int c_decode_varint(bytes s, int* p):
    cdef int r = 0
    cdef int shift = 0
    cdef char* c_s
    cdef int c_l
    PyString_AsStringAndSize(s, &c_s, &c_l)
    cdef char b
    while p[0] < c_l:
        b = c_s[p[0]]
        r |= ((b & 0x7f) << shift)
        p[0] += 1
        if not b & 0x80:
            break
        shift += 7
        if shift >= 64:
            raise Exception('too many bytes')

    return r

cpdef inline decode_varint(bytes s, int p):
    cdef int v = c_decode_varint(s, &p)
    return v, p

cdef inline c_chr(char n):
    return PyString_FromStringAndSize(&n, 1)

cpdef inline encode_varint(int n, write):
    cdef int b = n & 0x7f
    n >>= 7
    while n:
        write(c_chr(0x80|b))
        b = n & 0x7f
        n >>= 7
    write(c_chr(b))

cdef inline int decode_tag(bytes s, int* p):
    cdef int tag
    return c_decode_varint(s, p)

cdef inline void encode_tag(int findex, int wtype, write):
    cdef int tag = (findex << 3) | wtype
    encode_varint(tag, write)

cdef inline bytes decode_fixed(bytes s, int* p, int n):
    cdef bytes res = s[p[0] : p[0]+n]
    p[0] += n
    return res

cdef inline encode_fixed(bytes s, write):
    write(s)

cdef inline bytes c_decode_delimited(bytes s, int* p):
    cdef int l = c_decode_varint(s, p)
    return decode_fixed(s, p, l)

cpdef inline decode_delimited(bytes s, int p):
    cdef bytes s1 = c_decode_delimited(s, &p)
    return s1, p

cpdef inline encode_delimited(bytes s, write):
    encode_varint(len(s), write)
    write(s)

cpdef inline encode_string(s, write):
    return encode_delimited(s.encode('utf-8'), write)

cpdef inline decode_string(bytes s, int p):
    cdef bytes s1 = c_decode_delimited(s, &p)
    return s1.decode('utf-8'), p

cdef inline from_zigzag(int n):
    if not n & 0x1:
        return n >> 1
    return (n >> 1) ^ (~0)

cdef inline to_zigzag(int n):
    if n >= 0:
        return n << 1
    return (n << 1) ^ (~0)

cpdef inline decode_svarint(bytes s, int p):
    cdef int v = c_decode_varint(s, &p)
    return from_zigzag(v), p

cpdef inline encode_svarint(int n, write):
    encode_varint(to_zigzag(n), write)

cdef inline int skip_varint(bytes s, int p):
    cdef char* c_s
    cdef int c_l
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

encoders = {
    'int32': encode_varint,
    'int64': encode_varint,
    'sint32': encode_svarint,
    'sint64': encode_svarint,
    #'uint32': encode_uint32,
    #'uint64': encode_uint64,
    'bool': encode_varint,
    'enum': encode_varint,
    #'fixed64': encode_fixed64,
    #'sfixed64': encode_sfixed64,
    #'double': encode_double,
    'string': encode_string,
    'bytes': encode_delimited,
    #'fixed32': encode_fixed32,
    #'sfixed32': encode_sfixed32,
    #'float': encode_float,
}

decoders = {
    'int32': decode_varint,
    'int64': decode_varint,
    'sint32': decode_svarint,
    'sint64': decode_svarint,
    #'uint32': decode_uint32,
    #'uint64': decode_uint64,
    'bool': decode_varint,
    'enum': decode_varint,
    #'fixed64': decode_fixed64,
    #'sfixed64': decode_sfixed64,
    #'double': decode_double,
    'string': decode_string,
    'bytes': decode_delimited,
    #'fixed32': decode_fixed32,
    #'sfixed32': decode_sfixed32,
    #'float': decode_float,
}

class Field(object):
    def __init__(self, type, index, required=True, repeated=False, pack=False):
        self.type = type
        self.index = index
        self.required = required
        self.repeated = repeated
        self.pack = pack

        self.wire_type = self.get_wire_type()
        self.encoder = self.get_encoder()
        self.decoder = self.get_decoder()

    def get_wire_type(self):
        if self.pack:
            return 2
        try:
            return wire_types[self.type]
        except KeyError:
            assert isinstance(self.type, ProtoEntity)
            return 2

    def get_encoder(self):
        return encoders[self.type]

    def get_decoder(self):
        return decoders[self.type]

class MetaProtoEntity(type):
    def __new__(cls, clsname, bases, attrs):
        if clsname == 'ProtoEntity':
            return super(MetaProtoEntity, cls).__new__(cls, clsname, bases, attrs)
        # _decoders for decode
        # _fields for encode
        _fields = []
        _decoders = {}
        for name, f in attrs.items():
            if name.startswith('__'):
                continue
            _fields.append((
                f.index, f.wire_type, f.encoder, name
            ))
            _decoders[f.index] = (f.decoder, name)
        newcls = super(MetaProtoEntity, cls).__new__(cls, clsname, bases, attrs)
        newcls._fields = _fields
        newcls._decoders = _decoders
        return newcls

class ProtoEntity(object):
    __metaclass__ = MetaProtoEntity

    def __init__(self, **kwargs):
        for k,v in kwargs.items():
            setattr(self, k, v)

cpdef encode_object(obj):
    buf = []
    for findex, wtype, encoder, name in obj._fields:
        value = getattr(obj, name)
        encode_tag(findex, wtype, buf.append)
        encoder(value, buf.append)
    return ''.join(buf)

cpdef decode_object(cls, bytes s):
    decoders = cls._decoders
    cdef int p = 0
    cdef int tag, wtype, findex
    obj = cls()
    cdef int s_l = len(s)
    while p < s_l - 1:
        tag = decode_tag(s, &p)
        wtype= tag & 0x07
        findex = tag >> 3
        try:
            decoder, name = decoders[findex]
        except KeyError:
            p = skip_unknown_field(s, p, wtype)
        else:
            value, p = decoder(s, p)
            setattr(obj, name, value)

    return obj

if __name__ == '__main__':
    import doctest
    doctest.testmod()
