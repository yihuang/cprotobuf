#!/usr/bin/env python
from distutils.core import setup
from distutils.extension import Extension

try:
    from Cython.Distutils import build_ext
    have_cython = True
except ImportError:
    have_cython = False

if have_cython:
    ext_modules = [Extension("cprotobuf.internal", ["cprotobuf/internal.pyx"])
                   ]
    cmdclass = {'build_ext': build_ext}
else:
    cmdclass = {}
    ext_modules = [Extension("cprotobuf.internal", ["cprotobuf/internal.c"])
                   ]

setup(
    version='0.1.4',
    name='cprotobuf',
    ext_modules=ext_modules,
    scripts=['protoc-gen-cprotobuf'],
    packages=['cprotobuf'],
    author='huangyi',
    author_email='yi.codeplayer@gmail.com',
    url='https://github.com/yihuang/cprotobuf',
    description='pythonic and high performance protocol buffer implementation.',
    cmdclass=cmdclass,
    long_description=open('README.rst').read(),
)
