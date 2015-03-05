from cprotobuf import ProtoEntity, Field

s = b'\x10\x01\x08\x02\x1a\x02\x08\x01'


class SubMessage(ProtoEntity):
    a = Field('int32', 1)


class ForDecodeMessage(ProtoEntity):
    type = Field('int32', 1)
    count = Field('int32', 2, required=False)
    sub = Field('SubMessage', 3)


def test_decode_subobject():
    msg = ForDecodeMessage()
    msg.ParseFromString(s)
