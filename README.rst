A pure python implementation of protobuf encoding/decoding. intent to rewrite part of it to cython for performance.

Benchmark shows that current version is already faster than official expremental cpp python implementation.

::

  > ./setup.py build_ext --inplace
  > cd benchmark
  > ./bench.sh
  encode[google official pure python]:
  10 loops, best of 3: 68.8 msec per loop
  encode[google official cpp python]:
  100 loops, best of 3: 19.4 msec per loop
  encode[py-protobuf][cython]:
  100 loops, best of 3: 3.58 msec per loop
  decode[google official pure python]:
  10 loops, best of 3: 47.5 msec per loop
  decode[google official cpp python]:
  100 loops, best of 3: 4.55 msec per loop
  decode[py-protobuf][cython]:
  100 loops, best of 3: 3.98 msec per loop
