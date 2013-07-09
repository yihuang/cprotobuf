A pure python implementation of protobuf encoding/decoding. intent to rewrite part of it to cython for performance.

Benchmark shows that current version is already faster than official expremental cpp python implementation.

::

  > ./bench.sh
  encode[official pure python]:
  100 loops, best of 3: 7.58 msec per loop
  encode[official cpp python]:
  100 loops, best of 3: 3.23 msec per loop
  encode[py-protobuf]:
  100 loops, best of 3: 3.55 msec per loop
  encode[py-protobuf][pypy]:
  1000 loops, best of 3: 415 usec per loop
  decode[official pure python]:
  100 loops, best of 3: 5.42 msec per loop
  decode[official cpp python]:
  100 loops, best of 3: 2.14 msec per loop
  decode[py-protobuf]:
  100 loops, best of 3: 3.83 msec per loop
  decode[py-protobuf][pypy]:
  1000 loops, best of 3: 207 usec per loop
