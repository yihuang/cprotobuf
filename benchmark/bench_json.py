# coding: utf-8

import json


sub_test = {
    'a': None,
    'b': None,
}

test = {
    'a': None,
    'b': None,
    'c': None,
    'd': None,
    'e': None,
    'f': None,
    'g': None,
    'h': None,
    'i': None,
    'j': None,
    'k': None,
    'l': None,
    'm': None,
    'n': None,
    'o': sub_test,
    'p': [],
    'q': [],
    'r': [],
    's': None,
}

def encode():
    for i in range(500):
        t = {}
        t['a'] = 2147483647
        t['b'] = 9223372036854775807
        t['c'] = 2147483647
        t['d'] = 9223372036854775807
        t['e'] = 4294967295
        t['f'] = 18446744073709551615
        t['g'] = 2147483647
        t['h'] = 9223372036854775807
        t['i'] = 0.3
        t['j'] = 0.3
        t['k'] = 4294967295
        t['l'] = 18446744073709551615
        t['m'] = u'测试'
        t['n'] = True
        t['o'] = {'a': 150, 'b': -150}
        t['p'] = []
        t['p'].append(1)
        t['p'].append(2)
        t['p'].append(3)
        t['q'] = []
        t['q'].append(1)
        t['q'].append(2)
        t['q'].append(3)
        t['r'] = []
        t['r'].append({'a': 150, 'b': -150})
        t['r'].append({'a': 150, 'b': -150})
        t['s'] = 1
        json.dumps(t, encoding='UTF-8')

def decode():
    bs = '{"a": 2147483647, "c": 2147483647, "b": 9223372036854775807, "e": 4294967295, "d": 9223372036854775807, "g": 2147483647, "f": 18446744073709551615, "i": 0.3, "h": 9223372036854775807, "k": 4294967295, "j": 0.3, "m": "\u6d4b\u8bd5", "l": 18446744073709551615, "o": {"a": 150, "b": -150}, "n": true, "q": [1, 2, 3], "p": [1, 2, 3], "s": 1, "r": [{"a": 150, "b": -150}, {"a": 150, "b": -150}]}'
    for i in range(500):
        json.loads(bs)

if __name__ == '__main__':
    decode()
