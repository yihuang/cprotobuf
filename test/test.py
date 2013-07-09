from schema import ProtoEntity, Field, encode_object, decode_object
import test_pb2

class Test1(ProtoEntity):
    a = Field('int32', 1)
    b = Field('int32', 2, required=False, default=0)
    c = Field('int32', 3)
    d = Field('int32', 4, repeated=True)
    e = Field('int32', 5, repeated=True, pack=True)

def test():
    obj = test_pb2.Test1(a=200, c=100)
    obj.d.append(1)
    obj.d.append(2)
    obj.d.append(3)
    obj.e.append(1)
    obj.e.append(2)
    obj.e.append(3)
    bs = obj.SerializeToString()

    obj1 = Test1(a=200, c=100, d=[1,2,3], e=[1,2,3])
    bs1 = encode_object(obj1)

    obj2 = decode_object(Test1(), bs)
    assert obj2.a == 200
    assert obj2.c == 100
    assert len(obj2.d) == 3
    assert len(obj2.e) == 3

    obj3 = test_pb2.Test1()
    obj3.ParseFromString(bs1)
    assert obj3.a == 200
    assert obj3.c == 100
    assert len(obj3.d) == 3
    assert len(obj3.e) == 3

if __name__ == '__main__':
    test()
