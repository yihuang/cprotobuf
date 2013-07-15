# coding: utf-8
import itertools
import pyximport; pyximport.install()
from pyprotobuf import ProtoEntity, Field
import test_pb2

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

data1 = dict(
    a = 2147483647,
    b = 9223372036854775807,
    c = 2147483647,
    d = 9223372036854775807,
    e = 4294967295,
    f = 18446744073709551615,
    g = 2147483647,
    h = 9223372036854775807,
    i = 0.3,
    j = 0.3,
    k = 4294967295,
    l = 18446744073709551615,
    m = u'测试',
    n = True,
    o = dict(
        a = 150,
        b = -150,
    ),
    p = [1,2,3],
    q = [1,2,3],
    r = [
        dict(
            a = 150,
            b = -150
        ),
    ],
    s = test_pb2.TYPE1,
)

data2 = dict(
    a = -2147483647,
    b = -9223372036854775807,
    c = -2147483647,
    d = -9223372036854775807,
    e = 2147483647,
    f = 9223372036854775807,
    g = -2147483647,
    h = -9223372036854775807,
    i = -0.3,
    j = -0.3,
    k = 4294967295,
    l = 18446744073709551615,
    m = u'测试',
    n = False,
    s = test_pb2.TYPE2,
)

def set_obj(o, d):
    for k,v in d.items():
        if isinstance(v, dict):
            set_obj(getattr(o, k), v)
        elif isinstance(v, list):
            for i in v:
                attr = getattr(o, k)
                if isinstance(i, dict):
                    set_obj(attr.add(), i)
                else:
                    attr.append(i)
        else:
            setattr(o, k, v)

def eq_obj(data, obj1, obj2):
    for f, v in data.items():
        v1 = getattr(obj1, f)
        v2 = getattr(obj2, f)
        if isinstance(v, list):
            for a, b in itertools.izip_longest(v1, v2):
                if isinstance(v[0], dict):
                    eq_obj(v[0], a, b)
                else:
                    assert a==b, (f, a, b)
        elif isinstance(v, dict):
            eq_obj(v, v1, v2)
        else:
            assert v1==v2, (f, v1, v2)

def test(data):
    e_obj1 = test_pb2.Test()
    set_obj(e_obj1, data)
    e_obj2 = Test()
    set_obj(e_obj2, data)

    bs1 = e_obj1.SerializeToString()
    bs2 = str(e_obj2.SerializeToString())

    if len(bs1) != len(bs2):
        print len(bs1), repr(bs1)
        print len(bs2), repr(bs2)
        assert False, 'encoding result is not the same'

    obj1 = test_pb2.Test()
    obj1.ParseFromString(bs2)

    obj2 = Test()
    obj2.ParseFromString(bs1)

    eq_obj(data, obj1, obj2)

if __name__ == '__main__':
    test(data1)
    test(data2)
