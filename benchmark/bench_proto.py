# coding: utf-8
from test_pb2 import Test
def main():
    for i in range(500):
        Test(a=150, b=u'测试', c=-150).SerializeToString()
