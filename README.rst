A minimal fast protobuf implementation with cython.
Benchmark shows that it's much faster than google official expremental cpp-python implementation.

I've been using it in production since 2013, only tested with python2.7, feedback on other python release is welcome.

Benchmark
=========

.. code-block:: bash

  $ ./setup.py build_ext --inplace
  $ cd benchmark
  $ ./bench.sh
  encode[google official pure python]:
  10 loops, best of 3: 68.8 msec per loop
  encode[google official cpp python]:
  100 loops, best of 3: 19.4 msec per loop
  encode[py-protobuf][cprotobuf]:
  100 loops, best of 3: 3.58 msec per loop
  decode[google official pure python]:
  10 loops, best of 3: 47.5 msec per loop
  decode[google official cpp python]:
  100 loops, best of 3: 4.55 msec per loop
  decode[py-protobuf][cprotobuf]:
  100 loops, best of 3: 3.98 msec per loop

Tutorial
========

Use plugin
----------

You write a ``person.proto`` file like this:

.. code-block:: protobuf

    package foo;

    message Person {
      required int32 id = 1;
      required string name = 2;
      optional string email = 3;
    }

And a ``people.proto`` file like this:

.. code-block:: protobuf

    package foo;
    import "person.proto";

    message People {
      repeated Person people = 1;
    }

Then you compile it with provided plugin:

.. code-block:: bash

    $ protoc --cprotobuf_out=. person.proto people.proto

If you have trouble to run a protobuf plugin like on windows, you can directly run ``protoc-gen-cprotobuf`` like this:

.. code-block:: bash

    $ protoc -ofoo.pb person.proto people.proto
    $ protoc-gen-cprotobuf foo.pb -d .

Then you get a python module ``foo_pb.py`` , cprotobuf generate a python module for each package rather than each protocol file.

The generated code is quite readable:

.. code-block:: python

    # coding: utf-8
    from cprotobuf import ProtoEntity, Field
    # file: person.proto
    class Person(ProtoEntity):
        id              = Field('int32',	1)
        name            = Field('string',	2)
        email           = Field('string',	3, required=False)

    # file: people.proto
    class People(ProtoEntity):
        people          = Field(Person,	1, repeated=True)

Actually, if you only use python, you can write this python module, avoid code generation.

The API
-------

Now, you have this lovely python module, how to parse and serialize messages?

When design this package, We try to minimise the effort of migration, so we keep the names of api akin to protocol buffer's.

encode/decode
~~~~~~~~~~~~~

.. code-block:: python

    >>> from foo_pb import Person, People
    >>> msg = People()
    >>> msg.people.add(
    ...    id = 1,
    ...    name = 'jim',
    ...    email = 'jim@gmail.com',
    ... )
    >>> s = msg.SerializeToString()
    >>> msg2 = People()
    >>> msg2.ParseFromString(s)
    >>> len(msg2)
    1
    >>> msg2.people[0].name
    'jim'

reflection
~~~~~~~~~~

.. code-block:: python

    >>> from foo_pb import Person, People
    >>> dir(Person._fields[0])
    ['__class__', '__delattr__', '__doc__', '__format__', '__get__', '__getattribute__', '__hash__', '__init__', '__new__', '__pyx_vtable__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', 'index', 'name', 'packed', 'repeated', 'required', 'wire_type']
    >>> Person._fields[0].name
    'email'
    >>> Person._fieldsmap
    {1: <cprotobuf.Field object at 0xb74a538c>, 2: <cprotobuf.Field object at 0xb74a541c>, 3: <cprotobuf.Field object at 0xb74a5c8c>}
    >>> Person._fieldsmap_by_name
    {'email': <cprotobuf.Field object at 0xb74a5c8c>, 'name': <cprotobuf.Field object at 0xb74a541c>, 'id': <cprotobuf.Field object at 0xb74a538c>}

repeated container
~~~~~~~~~~~~~~~~~~

We use ``RepeatedContainer`` to represent repeated field, ``RepeatedContainer`` is inherited from ``list``, so you can manipulate it like a ``list``, or with apis like google's implementation.

.. code-block:: python

    >>> from foo_pb import Person, People
    >>> msg = People()
    >>> msg.people.add(
    ...    id = 1,
    ...    name = 'jim',
    ...    email = 'jim@gmail.com',
    ... )
    >>> p = msg.people.add()
    >>> p.id = 2
    >>> p.name = 'jake'
    >>> p.email = 'jake@gmail.com'
    >>> p2 = Person(id=3, name='lucy', email='lucy@gmail.com')
    >>> msg.people.append(p2)
    >>> msg.people.append({
    ...     'id' : 4,
    ...     'name' : 'lily',
    ...     'email' : 'lily@gmail.com',
    ... })

encode raw data fast
~~~~~~~~~~~~~~~~~~~~

If you already have your messages represented as ``list`` and ``dict``, you can encode it without constructing intermidiate objects, getting ride of a lot of overhead:

.. code-block:: python

    >>> from cprotobuf import encode_data
    >>> from foo_pb import Person, People
    >>> s = encode_data(People, [
    ...     { 'id': 1, 'name': 'tom', 'email': 'tom@gmail.com' }
    ... ])
    >>> msg = People()
    >>> msg.ParseFromString(s)
    >>> msg.people[0].name
    'tom'

Run Tests
=========

.. code-block::

    $ nosetests
