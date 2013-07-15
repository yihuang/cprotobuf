#!/usr/bin/env python
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

ext_modules = [ Extension("pyprotobuf", ["pyprotobuf.pyx"])
              ]

setup(
    name = 'py-protobuf',
    cmdclass = {'build_ext': build_ext},
    ext_modules = ext_modules,
    scripts = [ 'protoc-gen-cython' ],
)
