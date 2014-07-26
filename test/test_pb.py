# coding: utf-8
from cprotobuf import ProtoEntity, Field
# file: test.proto.proto
# enum TestType
TYPE1=-1
TYPE2=2
TYPE3=3
class SubTest(ProtoEntity):
    a               = Field('int32',	1, required=False)
    b               = Field('sint32',	2, required=False)

class SelfRef(ProtoEntity):
    self            = Field('SelfRef',	1, required=False)
    n               = Field('int32',	2, required=False)

class RecursiveFoo(ProtoEntity):
    bar             = Field('RecursiveBar',	1, required=False)
    n               = Field('int32',	2, required=False)

class Test(ProtoEntity):
    a               = Field('int32',	1, required=False)
    b               = Field('int64',	2, required=False)
    c               = Field('sint32',	3, required=False)
    d               = Field('sint64',	4, required=False)
    e               = Field('fixed32',	5, required=False)
    f               = Field('fixed64',	6, required=False)
    g               = Field('sfixed32',	7, required=False)
    h               = Field('sfixed64',	8, required=False)
    i               = Field('float',	9, required=False)
    j               = Field('double',	10, required=False)
    k               = Field('uint32',	11, required=False)
    l               = Field('uint64',	12, required=False)
    m               = Field('string',	13, required=False)
    n               = Field('bool',	14, required=False)
    o               = Field(SubTest,	15, required=False)
    p               = Field('int32',	16, repeated=True)
    q               = Field('int32',	17, repeated=True, packed=True)
    r               = Field(SubTest,	18, repeated=True)
    s               = Field('enum',	19, required=False)
    foo             = Field(RecursiveFoo,	20, required=False)
    self            = Field(SelfRef,	21, required=False)

class RecursiveBar(ProtoEntity):
    foo             = Field(RecursiveFoo,	1)

