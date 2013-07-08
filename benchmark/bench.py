# coding: utf-8
from schema import ProtoEntity, Field, encode_object, decode_object
class Test(ProtoEntity):
    a = Field('int32', 1)
    b = Field('string', 2)
    c = Field('sint32', 3)

def main():
    for i in range(500):
        encode_object(Test(a=150, b=u'测试', c=-150))
