A pure python implementation of protobuf encoding/decoding. intent to rewrite part of it to cython for performance.

Benchmark shows that current version is already faster than official expremental cpp python implementation.

::

  > ./setup.py build_ext --inplace
  > cd benchmark
  > ./bench.sh
  encode[official pure python]:
  100 loops, best of 3: 7.52 msec per loop
  encode[official cpp python]:
  100 loops, best of 3: 3.28 msec per loop
  encode[py-protobuf]:
  100 loops, best of 3: 3.51 msec per loop
  encode[py-protobuf][pypy]:
  1000 loops, best of 3: 411 usec per loop
  encode[py-protobuf][cython]:
  100 loops, best of 3: 3.19 msec per loop
  decode[official pure python]:
  100 loops, best of 3: 5.43 msec per loop
  decode[official cpp python]:
  100 loops, best of 3: 2.03 msec per loop
  decode[py-protobuf]:
  100 loops, best of 3: 3.83 msec per loop
  decode[py-protobuf][pypy]:
  1000 loops, best of 3: 208 usec per loop
  decode[py-protobuf][cython]:
  100 loops, best of 3: 3.24 msec per loop
