#!/bin/sh
export PYTHONPATH=..:$PYTHONPATH

#echo 'encode[google official pure python]:'
#export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
#python -mtimeit -s "import bench_proto as bench" "bench.encode()"
#echo 'encode[google official cpp python]:'
#export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
#python -mtimeit -s "import bench_proto as bench" "bench.encode()"
#echo 'encode[py-protobuf]:'
#python -mtimeit -s "import bench" "bench.encode()"
echo 'encode[py-protobuf][pypy]:'
pypy -mtimeit -s "import bench" "bench.encode()"
echo 'encode[py-protobuf][cython]:'
python -mtimeit -s "import bench_cython" "bench_cython.encode()"
echo 'encode[py-protobuf][experimental]:'
python -mtimeit -s "import bench_experimental" "bench_experimental.encode()"

#echo 'decode[google official pure python]:'
#export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
#python -mtimeit -s "import bench_proto as bench" "bench.decode()"
#echo 'decode[google official cpp python]:'
#export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
#python -mtimeit -s "import bench_proto as bench" "bench.decode()"
#echo 'decode[py-protobuf]:'
#python -mtimeit -s "import bench" "bench.decode()"
echo 'decode[py-protobuf][pypy]:'
pypy -mtimeit -s "import bench" "bench.decode()"
echo 'decode[py-protobuf][cython]:'
python -mtimeit -s "import bench_cython" "bench_cython.decode()"
echo 'decode[py-protobuf][experimental]:'
python -mtimeit -s "import bench_experimental" "bench_experimental.decode()"
