import pyximport; pyximport.install()
from cprotobuf import ProtoEntity, Field

s = b'\x08\x02\x10\x01\x1a\x07summons'

class TestMessage(ProtoEntity):
    type = Field('int32', 1)
    count = Field('int32', 2, required=False)
    nonexists = Field('int32', 4, required=False)

def test_skip():
    req = TestMessage()
    req.ParseFromString(s)
    assert req.type == 2
    assert req.count == 1
    assert 'nonexists' not in req.__dict__

if __name__ == '__main__':
    test_skip()
