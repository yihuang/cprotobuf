import pyximport; pyximport.install()
from pyprotobuf import ProtoEntity, Field

s = '\x08\x02\x10\x01\x1a\x07summons'

class TestMessage(ProtoEntity):
    type = Field('int32', 1)
    count = Field('int32', 2, required=False)

def test_skip():
    req = TestMessage()
    req.ParseFromString(s)
    assert req.type == 2
    assert req.count == 1

if __name__ == '__main__':
    test_skip()
