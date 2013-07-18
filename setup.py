#!/usr/bin/env python
from distutils.core import setup
from distutils.extension import Extension

ext_modules = [ Extension("pyprotobuf", ["pyprotobuf.c"])
              ]

setup(
    name = 'py-protobuf',
    ext_modules = ext_modules,
    scripts = [ 'protoc-gen-cython' ],
)
