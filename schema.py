#required int32 a = 1;
from internal import *

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
        newcls = super(MetaProtoEntity, cls).__new__(cls, clsname, bases, attrs)
        if clsname == 'ProtoEntity':
            return newcls
        # _decoders for decode
        # _fields for encode
        newcls._fields = []
        newcls._decoders = {}
        newcls._fieldnames = {}
        for name, f in attrs.items():
            if name.startswith('__'):
                continue
            newcls._fields.append((
                f.index, f.wire_type, f.encoder, name
            ))
            newcls._decoders[f.index] = f.decoder
            newcls._fieldnames[f.index] = name
        return newcls

class ProtoEntity(object):
    __metaclass__ = MetaProtoEntity

    def __init__(self, **kwargs):
        for k,v in kwargs.items():
            setattr(self, k, v)
