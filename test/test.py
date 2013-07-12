# coding: utf-8
import itertools
import pyximport; pyximport.install()
from c_internal import ProtoEntity, Field
import test_pb2

class SubTest(ProtoEntity):
    a = Field('int32', 1)
    b = Field('string', 2)

class Test1(ProtoEntity):
    a = Field('int32', 1)
    b = Field('int32', 2, required=False, default=0)
    c = Field('sint32', 3)
    d = Field('int32', 4, repeated=True)
    e = Field('sint32', 5, repeated=True, pack=True)
    f = Field('float', 6)
    g = Field('double', 7)
    h = Field(SubTest, 8)

def test():
    obj = test_pb2.Test1(a=-200, c=100, f=0.3, g=10.4)
    obj.d.append(1)
    obj.d.append(2)
    obj.d.append(3)
    obj.e.append(1)
    obj.e.append(2)
    obj.e.append(3)
    obj.h.a=150
    obj.h.b=u'测试'
    bs = obj.SerializeToString()

    obj1 = Test1(a=-200, c=100, d=[1,2,3], e=[1,2,3], f=0.3, g=10.4, h=SubTest(a=150, b=u'测试'))
    bs1 = obj1.SerializeToString()

    obj2 = Test1()
    obj2.ParseFromString(bs)

    obj3 = test_pb2.Test1()
    obj3.ParseFromString(bs1)

    assert obj2.a == obj3.a
    assert obj2.c == obj3.c
    assert obj2.f == obj3.f, (obj2.f, obj3.f)
    assert obj2.e == obj3.e
    assert obj2.h.a == obj3.h.a, (obj2.h.a, obj3.h.a)
    assert obj2.h.b == obj3.h.b, (obj2.h.b, obj3.h.b)

    for a,b in itertools.izip_longest(obj2.d, obj3.d):
        assert a==b

    for a,b in itertools.izip_longest(obj2.e, obj3.e):
        assert a==b

if __name__ == '__main__':
    test()
