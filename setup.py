from setuptools import setup
from Cython.Build import cythonize

setup(
    packages = ["cprotobuf"],
    name="cprotobuf",
    ext_modules=cythonize("cprotobuf/internal.pyx"),
)
