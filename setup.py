#!/usr/bin/env python
"""Setup script for cprotobuf with PyDust support.

This setup.py is maintained for backward compatibility.
For modern builds, use pyproject.toml with PyDust.
"""

from setuptools import setup

# Read version from pyproject.toml
import tomllib
with open("pyproject.toml", "rb") as f:
    pyproject = tomllib.load(f)
    version = pyproject["project"]["version"]

setup(
    version=version,
    name="cprotobuf",
    scripts=["protoc-gen-cprotobuf"],
    packages=["cprotobuf"],
    author="huangyi",
    author_email="yi.codeplayer@gmail.com",
    url="https://github.com/yihuang/cprotobuf",
    description="pythonic and high performance protocol buffer implementation.",
    long_description=open("README.rst").read(),
    python_requires=">=3.7",
)
