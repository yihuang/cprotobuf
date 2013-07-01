#required int32 a = 1;

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

decoders = {
}

class Field(object):
    def __init__(self, type, index, required=True, repeated=False, pack=False):
        self.type = type
        self.index = index
        self.required = required
        self.repeated = repeated
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
        try:
            return encoders[self.type]
        except KeyError:
            return 

    def get_decoder(self):
        pass

def MetaProtoEntity(clsname, bases, attrs):
    cls = type(clsname, bases, attrs)
    # __decoders for decode
    # __fields for encode
    cls.__fields = []
    for name, f in attrs.items():
        cls.__fields.append((
            f.index, f.wire_type, f.encoder, name
        ))
    return cls

class ProtoEntity(object):
    __metaclass__ = MetaProtoEntity
