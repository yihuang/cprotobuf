#!/bin/sh
export PYTHONPATH=..:$PYTHONPATH
echo 'official pure python:'
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
python -mtimeit -s "import bench_proto as bench" "bench.main()"
echo 'official cpp python:'
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
python -mtimeit -s "import bench_proto as bench" "bench.main()"
echo 'py-protobuf:'
python -mtimeit -s "import bench" "bench.main()"
