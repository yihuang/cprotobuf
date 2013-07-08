#!/bin/sh
export PYTHONPATH=..:$PYTHONPATH

echo 'encode[official pure python]:'
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
python -mtimeit -s "import bench_proto as bench" "bench.encode()"
echo 'encode[official cpp python]:'
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
python -mtimeit -s "import bench_proto as bench" "bench.encode()"
echo 'encode[py-protobuf]:'
python -mtimeit -s "import bench" "bench.encode()"

echo 'decode[official pure python]:'
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
python -mtimeit -s "import bench_proto as bench" "bench.decode()"
echo 'decode[official cpp python]:'
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
python -mtimeit -s "import bench_proto as bench" "bench.decode()"
echo 'decode[py-protobuf]:'
python -mtimeit -s "import bench" "bench.decode()"
