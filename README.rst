A pure python implementation of protobuf encoding/decoding. intent to rewrite part of it to cython for performance.

Benchmark shows that current version is already faster than official expremental cpp python implementation.

::

  > ./setup.py build_ext --inplace
  > cd benchmark
  > ./bench.sh
  encode[google official pure python]:
  100 loops, best of 3: 7.52 msec per loop
  encode[google official cpp python]:
  100 loops, best of 3: 3.32 msec per loop
  encode[py-protobuf]:
  100 loops, best of 3: 3.43 msec per loop
  encode[py-protobuf][pypy]:
  1000 loops, best of 3: 398 usec per loop
  encode[py-protobuf][cython]:
  1000 loops, best of 3: 1.03 msec per loop
  decode[google official pure python]:
  100 loops, best of 3: 5.46 msec per loop
  decode[google official cpp python]:
  100 loops, best of 3: 2.14 msec per loop
  decode[py-protobuf]:
  100 loops, best of 3: 3.92 msec per loop
  decode[py-protobuf][pypy]:
  1000 loops, best of 3: 210 usec per loop
  decode[py-protobuf][cython]:
  1000 loops, best of 3: 467 usec per loop
