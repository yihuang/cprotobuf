A pure python implementation of protobuf encoding/decoding. intent to rewrite part of it to cython for performance.

Benchmark shows that current version is already faster than official expremental cpp python implementation.

::

  > ./setup.py build_ext --inplace
  > cd benchmark
  > ./bench.sh
  encode[google official pure python]:
  10 loops, best of 3: 28.5 msec per loop
  encode[google official cpp python]:
  100 loops, best of 3: 7.32 msec per loop
  encode[py-protobuf][experimental]:
  1000 loops, best of 3: 1.45 msec per loop
  decode[google official pure python]:
  10 loops, best of 3: 21.3 msec per loop
  decode[google official cpp python]:
  100 loops, best of 3: 3.11 msec per loop
  decode[py-protobuf][experimental]:
  1000 loops, best of 3: 1.74 msec per loop
