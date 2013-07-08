# coding: utf-8
from schema import ProtoEntity, Field, encode_object, decode_object
class Test(ProtoEntity):
    a = Field('int32', 1)
    b = Field('string', 2)
    c = Field('sint32', 3)

def encode():
    for i in range(500):
        t = Test()
        t.a = 150
        t.b = u'测试'
        t.c = -150
        encode_object(t)

def decode():
    bs = '\x08\x96\x01\x12\x06\xe6\xb5\x8b\xe8\xaf\x95\x18\xab\x02'
    for i in range(500):
        decode_object(Test, bs)

if __name__ == '__main__':
    decode()
