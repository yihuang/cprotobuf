# coding: utf-8
from internal import decode_message, encode_message
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
    r'''
    >>> bs = encode_object(Test1(a=150, b=u'\u6d4b\u8bd5', c=-150))
    >>> from internal import decode_wire_message
    >>> decode_wire_message(bs)
    [(1, 150), (2, '\xe6\xb5\x8b\xe8\xaf\x95'), (3, 299)]
    '''
    l = []
    for findex, wtype, encoder, name in obj._fields:
        l.append( (findex, wtype, getattr(obj, name), encoder) )

    buf = []
    encode_message(l, buf.append)
    return ''.join(buf)

def decode_object(cls, s):
    r'''
    >>> bs = encode_object(Test1(a=150, b=u'\u6d4b\u8bd5', c=-150))
    >>> obj = decode_object(Test1, bs)
    >>> obj.a
    150
    >>> obj.b
    u'\u6d4b\u8bd5'
    >>> obj.c
    -150
    '''
    l = decode_message(s, cls._decoders)
    obj = cls()
    names = cls._fieldnames
    for findex, value in l:
        setattr(obj, names[findex], value)
    return obj

if __name__ == '__main__':
    import doctest
    doctest.testmod()
