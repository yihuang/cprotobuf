A minimal fast protobuf implementation with cython.
Benchmark shows that it's much faster than google official expremental cpp-python implementation.

Benchmark
=========

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

Tutorial
========

Pure python
-----------

Use plugin
----------

You write a `person.proto` file like this:

.. code-block:: protobuf

    package foo;

    message Person {
      required int32 id = 1;
      required string name = 2;
      optional string email = 3;
    }

and a `people.proto` file like this:

.. code-block:: protobuf

    package foo;
    import "person.proto";

    message People {
      repeated Person people = 1;
    }

Then you compile it with provided plugin:

.. code-block:: bash

    protoc --cython_out=. person.proto people.proto

You get a module `foo_pb.py` , the generated code is quit readable:

.. code-block:: python

    # coding: utf-8
    from pyprotobuf import ProtoEntity, Field
    # file: person.proto.proto
    class Person(ProtoEntity):
        id              = Field('int32',	1)
        name            = Field('string',	2)
        email           = Field('string',	3, required=False)

    # file: people.proto.proto
    class People(ProtoEntity):
        people          = Field(Person,	1, repeated=True)

