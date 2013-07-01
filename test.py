# coding: utf-8
from decode import decode_message, encode_message
from schema import ProtoEntity, Field

class Test2(ProtoEntity):
    a = Field('int32', 1)
    b = Field('string', 2)

class Test1(ProtoEntity):
    a = Field('int32', 1)
    b = Field('string', 2)
    c = Field('sint32', 3)
    #d = RepeatedField('int32', 4, repeated=True)
    #e = Field(Test2, 5)

def encode_object(obj):
    '''
    >>> encode_object(Test1(a=150, b=u'', c=-150))
    ''
    '''
    l = []
    for findex, wtype, encoder, name in obj.__fields:
        l.append( (findex, wtype, getattr(obj, name), encoder) )

    buf = []
    encode_message(l, buf.append)
    return ''.join(buf)

def decode_object(cls, s):
    return decode_message(s, cls.__decoders)
