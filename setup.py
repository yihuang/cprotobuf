#!/usr/bin/env python
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

ext_modules = [ Extension("c_schema", ["schema.pyx"])
              , Extension("c_internal", ["internal.pyx"])
              ]

setup(
    name = 'py-protobuf',
    cmdclass = {'build_ext': build_ext},
    ext_modules = ext_modules
)
