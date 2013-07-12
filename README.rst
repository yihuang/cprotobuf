A pure python implementation of protobuf encoding/decoding. intent to rewrite part of it to cython for performance.

Benchmark shows that current version is already faster than official expremental cpp python implementation.

::

  > ./setup.py build_ext --inplace
  > cd benchmark
  > ./bench.sh
  encode[google official pure python]:
  100 loops, best of 3: 7.47 msec per loop
  encode[google official cpp python]:
  100 loops, best of 3: 3.35 msec per loop
  encode[py-protobuf]:
  100 loops, best of 3: 3.77 msec per loop
  encode[py-protobuf][pypy]:
  1000 loops, best of 3: 348 usec per loop
  encode[py-protobuf][cython]:
  1000 loops, best of 3: 957 usec per loop
  decode[google official pure python]:
  100 loops, best of 3: 5.42 msec per loop
  decode[google official cpp python]:
  100 loops, best of 3: 2.1 msec per loop
  decode[py-protobuf]:
  100 loops, best of 3: 4.33 msec per loop
  decode[py-protobuf][pypy]:
  1000 loops, best of 3: 272 usec per loop
  decode[py-protobuf][cython]:
  1000 loops, best of 3: 344 usec per loop
