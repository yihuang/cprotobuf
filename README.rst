A pure python implementation of protobuf encoding/decoding. intent to rewrite part of it to cython for performance.

Benchmark shows that current version is already faster than official expremental cpp python implementation.

::

  > ./bench.sh
  100 loops, best of 3: 3.97 msec per loop
  100 loops, best of 3: 8.1 msec per loop
  100 loops, best of 3: 4.59 msec per loop
