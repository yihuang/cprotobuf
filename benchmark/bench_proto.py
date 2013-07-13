# coding: utf-8
from test_pb2 import Test
def encode():
    for i in range(500):
        t = Test()
        t.a = i
        t.b = u'测试'
        t.c = -i
        t.d.append(1)
        t.d.append(2)
        t.d.append(3)
        t.e.append(1)
        t.e.append(2)
        t.e.append(3)
        t.f = 0.3
        t.g = 10.4
        t.SerializeToString()

def decode():
    bs = '\x08\xe2\x03\x12\x06\xe6\xb5\x8b\xe8\xaf\x95*\x03\x01\x02\x03 \x01 \x02 \x039\xcd\xcc\xcc\xcc\xcc\xcc$@5\x9a\x99\x99>\x18\xc3\x07'
    for i in range(1):
        t = Test()
        t.ParseFromString(bs)
        print t

if __name__ == '__main__':
    decode()
