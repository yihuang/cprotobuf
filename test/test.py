# coding: utf-8
import itertools
import pyximport; pyximport.install()
from c_test import ProtoEntity, Field
import test_pb2

class Test1(ProtoEntity):
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

d = dict(
    a = 2147483647,
    b = 
)

def test():
    obj = test_pb2.Test1()
    bs = obj.SerializeToString()

    obj1 = Test1(a=-200, c=100, d=[1,2,3], e=[1,2,3], f=0.3, g=10.4)#, h=SubTest(a=150, b=u'测试')
    bs1 = obj1.SerializeToString()

    obj2 = Test1()
    obj2.ParseFromString(bs)

    obj3 = test_pb2.Test1()
    obj3.ParseFromString(bs1)

    assert obj2.a == obj3.a, (obj2.a, obj3.a)
    assert obj2.c == obj3.c
    assert obj2.f == obj3.f, (obj2.f, obj3.f)
    assert obj2.e == obj3.e
    #assert obj2.h.a == obj3.h.a, (obj2.h.a, obj3.h.a)
    #assert obj2.h.b == obj3.h.b, (obj2.h.b, obj3.h.b)

    for a,b in itertools.izip_longest(obj2.d, obj3.d):
        assert a==b

    for a,b in itertools.izip_longest(obj2.e, obj3.e):
        assert a==b

if __name__ == '__main__':
    test()
