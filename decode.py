def decode_varint(s, p):
    '''
    >>> decode_varint('\x08\x96\x01', 0)
    (8, 1)
    >>> decode_varint('\xac\x02', 0)
    (8, 1)
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

def decode_message(s):
    p = 0
    tag, p = decode_varint(s, p)
    tag >> 3

if __name__ == '__main__':
    import doctest
    doctest.testmod()
