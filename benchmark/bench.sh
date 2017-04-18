#!/bin/sh
export PYTHONPATH=..:$PYTHONPATH

echo 'encode[google official pure python]:'
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
python -mtimeit -s "import bench_proto as bench" "bench.encode()"
echo 'encode[google official cpp python]:'
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
python -mtimeit -s "import bench_proto as bench" "bench.encode()"
echo 'encode[official-json]:'
python -mtimeit -s "import bench_json" "bench_json.encode()"
echo 'encode[py-protobuf][cython]:'
python -mtimeit -s "import bench_cython" "bench_cython.encode()"

echo 'decode[google official pure python]:'
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
python -mtimeit -s "import bench_proto as bench" "bench.decode()"
echo 'decode[google official cpp python]:'
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
python -mtimeit -s "import bench_proto as bench" "bench.decode()"
echo 'decode[official-json]:'
python -mtimeit -s "import bench_json" "bench_json.decode()"
echo 'decode[py-protobuf][cython]:'
python -mtimeit -s "import bench_cython" "bench_cython.decode()"
