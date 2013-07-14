# coding: utf-8

import pyximport; pyximport.install()
from c_internal import ProtoEntity, Field

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
    k = Field('uint32',     11)
    l = Field('uint64',     12)
    m = Field('string',     13)

def encode():
    for i in range(500):
        t = Test()
        t.a = 2147483647
        t.b = 9223372036854775807
        t.c = 2147483647
        t.d = 9223372036854775807
        t.e = 4294967295
        t.f = 18446744073709551615
        t.g = 2147483647
        t.h = 9223372036854775807
        t.i = 0.3
        t.j = 0.3
        t.k = 4294967295
        t.l = 18446744073709551615
        t.m = u'测试'
        t.SerializeToString()

def decode():
    bs = '\x08\x81\x80\x80\x80\xf8\xff\xff\xff\xff\x01\x10\x81\x80\x80\x80\x80\x80\x80\x80\x80\x01\x18\xfd\xff\xff\xff\x0f \xfd\xff\xff\xff\xff\xff\xff\xff\xff\x01-\xff\xff\xff\x7f1\xff\xff\xff\xff\xff\xff\xff\x7f=\x01\x00\x00\x80A\x01\x00\x00\x00\x00\x00\x00\x80M\x9a\x99\x99\xbeQ333333\xd3\xbfX\xff\xff\xff\xff\x0f`\xff\xff\xff\xff\xff\xff\xff\xff\xff\x01j\x06\xe6\xb5\x8b\xe8\xaf\x95'
    for i in range(500):
        t = Test()
        t.ParseFromString(bs)

if __name__ == '__main__':
    decode()
