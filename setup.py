#!/usr/bin/env python
from distutils.core import setup
from distutils.extension import Extension

ext_modules = [ Extension("cprotobuf/internal", ["cprotobuf/internal.c"])
              ]

setup(
    version='0.1.1',
    name = 'cprotobuf',
    ext_modules = ext_modules,
    scripts = [ 'protoc-gen-cprotobuf' ],
    packages = ['cprotobuf'],
    author='huangyi',
    author_email='yi.codeplayer@gmail.com',
    url = 'https://github.com/yihuang/cprotobuf',
    description = 'pythonic and high performance protocol buffer implementation.',
    long_description=open('README.rst').read(),
)
