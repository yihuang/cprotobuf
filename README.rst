A pure python implementation of protobuf encoding/decoding. intent to rewrite part of it to cython for performance.

Benchmark shows that current version is already faster than official expremental cpp python implementation.

::

  > ./setup.py build_ext --inplace
  > cd benchmark
  > ./bench.sh
  encode[google official pure python]:
  100 loops, best of 3: 18 msec per loop
  encode[google official cpp python]:
  100 loops, best of 3: 7.07 msec per loop
  encode[py-protobuf]:
  100 loops, best of 3: 7.97 msec per loop
  encode[py-protobuf][pypy]:
  1000 loops, best of 3: 637 usec per loop
  encode[py-protobuf][cython]:
  1000 loops, best of 3: 1.71 msec per loop
  decode[google official pure python]:
  100 loops, best of 3: 14.4 msec per loop
  decode[google official cpp python]:
  100 loops, best of 3: 2.34 msec per loop
  decode[py-protobuf]:
  100 loops, best of 3: 10.8 msec per loop
  decode[py-protobuf][pypy]:
  1000 loops, best of 3: 428 usec per loop
  decode[py-protobuf][cython]:
  1000 loops, best of 3: 844 usec per loop
