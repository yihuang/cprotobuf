# coding: utf-8

import pyximport; pyximport.install()
from c_internal import ProtoEntity, Field, encode_object, decode_object

class Test(ProtoEntity):
    a = Field('int32', 1)
    b = Field('string', 2)
    c = Field('sint32', 3)
    d = Field('int32', 4, repeated=True)
    e = Field('int32', 5, repeated=True, pack=True)

def encode():
    for i in range(500):
        t = Test()
        t.a = i
        t.b = u'测试'
        t.c = -i
        t.d = [1,2,3]
        t.e = [1,2,3]
        encode_object(t)

def decode():
    bs = '\x08\x00\x12\x06\xe6\xb5\x8b\xe8\xaf\x95*\x03\x01\x02\x03 \x01 \x02 \x03\x18\x00'
    for i in range(500):
        decode_object(Test(), bs)

if __name__ == '__main__':
    encode()
