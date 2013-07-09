# coding: utf-8
from test_pb2 import Test
def encode():
    for i in range(500):
        t = Test()
        t.a = i
        t.b = u'测试'
        t.c = -i
        t.SerializeToString()

def decode():
    bs = '\x08\x96\x01\x12\x06\xe6\xb5\x8b\xe8\xaf\x95\x18\xab\x02'
    for i in range(500):
        t = Test()
        t.ParseFromString(bs)

if __name__ == '__main__':
    decode()
