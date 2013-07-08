def decode_varint(s, p):
    '''
    >>> decode_varint('\x08\x96\x01', 0)
    (8, 1)
    >>> decode_varint('\xac\x02', 0)
    (300, 2)
    '''
    r = 0
    shift = 0
    while True:
        b = ord(s[p])
        r |= ((b & 0x7f) << shift)
        p += 1
        if not b & 0x80:
            break
        shift += 7
        if shift >= 64:
            raise Exception('too many bytes')

    return r, p

def encode_varint(n, write):
    r'''
    >>> buf = []
    >>> encode_varint(150, buf.append)
    >>> ''.join(buf)
    '\x96\x01'
    '''
    b = n & 0x7f
    n >>= 7
    while n:
        write(chr(0x80|b))
        b = n & 0x7f
        n >>= 7
    write(chr(b))

def decode_tag(s, p):
    r'''
    >>> decode_tag('\x08', 0)
    (0, 1, 1)
    >>> decode_tag('\xb0\t', 0)
    (0, 150, 2)
    '''
    tag, p = decode_varint(s, p)
    return tag & 0x07, tag >> 3, p

def encode_tag(findex, wtype, write):
    r'''
    >>> buf = []
    >>> encode_tag(1, 0, buf.append)
    >>> ''.join(buf)
    '\x08'
    >>> buf = []
    >>> encode_tag(150, 0, buf.append)
    >>> ''.join(buf)
    '\xb0\t'
    '''
    tag = (findex << 3) | wtype
    encode_varint(tag, write)

def decode_fixed(s, p, n):
    return s[p:p+n], p+n

def encode_fixed(s, write):
    write(s)

def decode_delimited(s, p):
    l, p = decode_varint(s, p)
    return decode_fixed(s, p, l)

def encode_delimited(s, write):
    encode_varint(len(s), write)
    write(s)

def encode_string(s, write):
    return encode_delimited(s.encode('utf-8'), write)

def decode_string(s, p):
    _s, p = decode_delimited(s, p)
    return _s.decode('utf-8'), p

def from_zigzag(n):
    r'''
    >>> from_zigzag(299)
    -150
    '''
    if not n & 0x1:
        return n >> 1
    return (n >> 1) ^ (~0)

def to_zigzag(n):
    r'''
    >>> to_zigzag(-150)
    299
    '''
    if n >= 0:
        return n << 1
    return (n << 1) ^ (~0)

def decode_svarint(s, p):
    v, p = decode_varint(s, p)
    return from_zigzag(v), p

def encode_svarint(n, write):
    encode_varint(to_zigzag(n), write)

def decode_wire_message(s):
    r'''
    simple message from protobuf documentation:
    >>> decode_wire_message('\x08\x96\x01')
    [(1, 150)]

    test message from ref/test.proto
    >>> s = '\x08\x96\x01\x12\x0c\xe6\xb5\x8b\xe8\xaf\x95\xe6\xb5\x8b\xe8\xaf\x95\x18\xab\x02 \x01 \x02 \x03*\x03\x01\x02\x03'
    >>> res = decode_wire_message(s)
    >>> res[0]
    (1, 150)
    >>> res[1][1].decode('utf-8')
    u'\u6d4b\u8bd5\u6d4b\u8bd5'
    >>> from_zigzag(res[2][1])
    -150
    >>> res[3][1], res[4][1], res[5][1]
    (1, 2, 3)
    >>> res[6]
    (5, '\x01\x02\x03')
    '''
    p = 0
    result = []
    while p<len(s)-1:
        wtype, findex, p = decode_tag(s, p)
        if wtype == 0:
            value, p = decode_varint(s, p)
        elif wtype == 1:
            value, p = decode_fixed(s, p, 8)
        elif wtype == 2:
            value, p = decode_delimited(s, p)
        elif wtype == 5:
            value, p = decode_fixed(s, p, 4)
        else:
            raise Exception('impossible')

        result.append( (findex, value) )

    return result

def encode_wire_message(l, write):
    for findex, wtype, value in l:
        encode_tag(findex, wtype, write)
        if wtype == 0:
            encode_varint(value, write)
        elif wtype == 1:
            encode_fixed(value, write)
        elif wtype == 2:
            encode_delimited(value, write)
        elif wtype == 5:
            encode_fixed(value, write)
        else:
            raise Exception('impossible')

def skip_varint(s, p):
    if ord(s[p]) & 0x80:
        p += 1
    return p + 1

def skip_delimited(s, p):
    l, p = decode_varint(s, p)
    return p + l

def skip_unknown_field(s, p, wtype):
    if wtype == 0:
        p = skip_varint(s, p)
    elif wtype == 1:
        p += 8
    elif wtype == 2:
        p = skip_delimited(s, p)
    elif wtype == 5:
        p += 4
    else:
        raise Exception('impossible')
    return p

def decode_message(s, decoders):
    p = 0
    result = []
    while p<len(s)-1:
        wtype, findex, p = decode_tag(s, p)
        try:
            decoder, name = decoders[findex]
        except KeyError:
            p = skip_unknown_field(s, p, wtype)
        else:
            value, p = decoder(s, p)
            result.append((findex, name, value))

    return result

def encode_message(l, write):
    for findex, wtype, value, encoder in l:
        encode_tag(findex, wtype, write)
        encoder(value, write)

if __name__ == '__main__':
    import doctest
    doctest.testmod()
