#!/usr/bin/env python
from distutils.core import setup
from distutils.extension import Extension

ext_modules = [ Extension("cprotobuf/internal", ["cprotobuf/internal.c"])
              ]

setup(
    name = 'cprotobuf',
    ext_modules = ext_modules,
    scripts = [ 'protoc-gen-cprotobuf' ],
    packages = ['cprotobuf'],
    url = 'https://github.com/yihuang/cprotobuf',
)
