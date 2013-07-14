# coding: utf-8
from test_pb2 import Test

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
        t.SerializeToString()

def decode():
    bs = '\x08\xff\xff\xff\xff\x07\x10\xff\xff\xff\xff\xff\xff\xff\xff\x7f\x18\xfe\xff\xff\xff\x0f \xfe\xff\xff\xff\xff\xff\xff\xff\xff\x01-\xff\xff\xff\xff1\xff\xff\xff\xff\xff\xff\xff\xff=\xff\xff\xff\x7fA\xff\xff\xff\xff\xff\xff\xff\x7fM\x9a\x99\x99>Q333333\xd3?X\xff\xff\xff\xff\x0f`\xff\xff\xff\xff\xff\xff\xff\xff\xff\x01j\x06\xe6\xb5\x8b\xe8\xaf\x95p\x01z\x06\x08\x96\x01\x10\xab\x02\x80\x01\x01\x80\x01\x02\x80\x01\x03\x8a\x01\x03\x01\x02\x03'
    for i in range(500):
        t = Test()
        t.ParseFromString(bs)

if __name__ == '__main__':
    decode()
