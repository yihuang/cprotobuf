# coding: utf-8
from schema import ProtoEntity, Field, encode_object, decode_object

class Test(ProtoEntity):
    a = Field('int32',      1)
    b = Field('int64',      2)
    c = Field('sint32',     3)
    d = Field('sint64',     4)
    e = Field('fixed32',    5)
    f = Field('fixed64',    6)
    g = Field('sfixed32',   7)
    h = Field('sfixed64',   8)
    i = Field('float',      9)
    j = Field('double',     10)
    k = Field('string',     11)

def encode():
    for i in range(500):
        t = Test()
        t.a = 2147483647
        t.b = u'测试'
        t.c = -i
        t.d = [1,2,3]
        t.e = [1,2,3]
        t.f = 0.3
        t.g = 10.4
        t.h = -21474836470000
        t.SerializeToString()

def decode():
    bs = '\x08\n\x12\x06\xe6\xb5\x8b\xe8\xaf\x95\x18\x13'
    for i in range(500):
        t = Test()
        t.ParseFromString(bs)

if __name__ == '__main__':
    encode()
