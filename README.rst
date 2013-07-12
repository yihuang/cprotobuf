A pure python implementation of protobuf encoding/decoding. intent to rewrite part of it to cython for performance.

Benchmark shows that current version is already faster than official expremental cpp python implementation.

::

  > ./setup.py build_ext --inplace
  > cd benchmark
  > ./bench.sh
  encode[google official pure python]:
  100 loops, best of 3: 17.7 msec per loop
  encode[google official cpp python]:
  100 loops, best of 3: 7.04 msec per loop
  encode[py-protobuf]:
  100 loops, best of 3: 7.97 msec per loop
  encode[py-protobuf][pypy]:
  1000 loops, best of 3: 640 usec per loop
  encode[py-protobuf][cython]:
  1000 loops, best of 3: 1.3 msec per loop
  decode[google official pure python]:
  100 loops, best of 3: 14.2 msec per loop
  decode[google official cpp python]:
  100 loops, best of 3: 2.3 msec per loop
  decode[py-protobuf]:
  100 loops, best of 3: 11 msec per loop
  decode[py-protobuf][pypy]:
  1000 loops, best of 3: 448 usec per loop
  decode[py-protobuf][cython]:
  1000 loops, best of 3: 888 usec per loop
