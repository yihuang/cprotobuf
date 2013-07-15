# coding: utf-8

import pyximport; pyximport.install()
from c_test import ProtoEntity, Field

TYPE1 = 1
TYPE2 = 1
TYPE3 = 1

class SubTest(ProtoEntity):
    a = Field('int32',      1)
    b = Field('sint32',     2)

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
    n = Field('bool',       14)
    o = Field(SubTest,      15)
    p = Field('int32',      16, repeated=True)
    q = Field('int32',      17, repeated=True, packed=True)
    r = Field(SubTest,      18, repeated=True)
    s = Field('enum',       19)

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
        t.n = True
        t.o.a = 150
        t.o.b = -150
        t.p.append(1)
        t.p.append(2)
        t.p.append(3)
        t.q.append(1)
        t.q.append(2)
        t.q.append(3)
        r = t.r.add()
        r.a = 150
        r.b = -150
        r = t.r.add()
        r.a = 150
        r.b = -150
        t.s = TYPE2
        t.SerializeToString()

def decode():
    bs = '\x08\xff\xff\xff\xff\x07\x10\xff\xff\xff\xff\xff\xff\xff\xff\x7f\x18\xfe\xff\xff\xff\x0f \xfe\xff\xff\xff\xff\xff\xff\xff\xff\x01-\xff\xff\xff\xff1\xff\xff\xff\xff\xff\xff\xff\xff=\xff\xff\xff\x7fA\xff\xff\xff\xff\xff\xff\xff\x7fM\x9a\x99\x99>Q333333\xd3?X\xff\xff\xff\xff\x0f`\xff\xff\xff\xff\xff\xff\xff\xff\xff\x01j\x06\xe6\xb5\x8b\xe8\xaf\x95p\x01z\x06\x08\x96\x01\x10\xab\x02\x80\x01\x01\x80\x01\x02\x80\x01\x03\x8a\x01\x03\x01\x02\x03\x92\x01\x06\x08\x96\x01\x10\xab\x02\x92\x01\x06\x08\x96\x01\x10\xab\x02'
    for i in range(500):
        t = Test()
        t.ParseFromString(bs)

if __name__ == '__main__':
    encode()
