from cpython cimport *
from libc.stdint cimport *

# {{{ definitions

cdef extern from "bytearrayobject.h":

    ctypedef class __builtin__.bytearray [object PyByteArrayObject]:
        cdef Py_ssize_t ob_alloc
        cdef char *ob_bytes
        cdef Py_ssize_t ob_size

cdef extern from "Python.h":
    Py_ssize_t PyByteArray_GET_SIZE(object array)
    object PyUnicode_FromStringAndSize(char *buff, Py_ssize_t len)

ctypedef object(*Decoder)(char **pointer, char *end)
ctypedef object(*Encoder)(bytearray array, object value)

class InternalDecodeError(Exception):
    pass

cdef inline object makeDecodeError(char* pointer, message):
    cdef uint64_t locator = <uint64_t>pointer
    return InternalDecodeError(locator, message)

class DecodeError(Exception):
    def __init__(self, pointer, message):
        self.pointer = pointer
        self.message = message
    def __str__(self):
        return self.message.format(self.pointer)

cdef inline int bytearray_reserve(bytearray ba, Py_ssize_t size) except -1:
    cdef Py_ssize_t alloc = ba.ob_alloc
    if size <= alloc:
        return 0

    alloc = size + (size >> 3) + 16

    cdef void *sval = PyMem_Realloc(ba.ob_bytes, alloc)
    if sval == NULL:
        raise MemoryError
    ba.ob_alloc = alloc
    ba.ob_bytes = <char*>sval
    return 0

cdef inline int bytearray_resize(bytearray array, Py_ssize_t size) except -1:
    bytearray_reserve(array, size)
    array.ob_size = size
    array.ob_bytes[size] = '\0';

# }}}

# {{{ decoding

# {{{ raw stuff

cdef inline int raw_decode_uint32(char **start, char *end, uint32_t *result) nogil:
    cdef uint32_t value = 0
    cdef uint32_t byte
    cdef char *pointer = start[0]
    cdef int counter = 0
    while True:
        if pointer == end:
            return -1
        byte = pointer[0]
        value |= (byte & 0x7f) << counter
        counter+=7
        pointer+=1
        if byte & 0x80 == 0:
            break
    start[0] = pointer
    result[0] = value
    return 0

cdef inline int raw_decode_uint64(char **start, char *end, uint64_t *result) nogil:
    cdef uint64_t value = 0
    cdef uint64_t byte
    cdef char *pointer = start[0]
    cdef int counter = 0
    while True:
        if pointer == end:
            return -1
        byte = pointer[0]
        value |= (byte & 0x7f) << counter
        counter+=7
        pointer+=1
        if byte & 0x80 == 0:
            break
    start[0] = pointer
    result[0] = value
    return 0

cdef inline int raw_decode_fixed32(char **pointer, char *end, uint32_t *result) nogil:
    cdef uint32_t value = 0
    cdef char *start = pointer[0]
    cdef int i

    for i from 0 <= i < 4:
        if start == end:
            return -1
        value |= <unsigned char>start[0] << (i * 8)
        start += 1
    pointer[0] = start
    result[0] = value
    return 0

cdef inline int raw_decode_fixed64(char **pointer, char *end, uint64_t *result) nogil:
    cdef uint64_t value = 0
    cdef char *start = pointer[0]
    cdef uint64_t temp = 0
    cdef int i
    for i from 0 <= i < 8:
        if start == end:
            return -1
        temp = <unsigned char>start[0]
        value |= temp << (i * 8)
        start += 1
    pointer[0] = start
    result[0] = value
    return 0

cdef inline int raw_decode_delimited(char **pointer, char *end, char **result, uint64_t *size) nogil:
    if raw_decode_uint64(pointer, end, size):
        return -1

    cdef char* start = pointer[0]
    if start+size[0] > end:
        return -2

    result[0] = start
    pointer[0] = start+size[0]
    return 0

cdef inline int skip_unknown_field(char **pointer, char *end, int wtype) nogil:
    cdef uint32_t size
    cdef char* start
    if wtype == 0:
        start = pointer[0]
        while True:
            if start >= end:
                return -1
            if start[0] & 0x80 == 0:
                break
            start += 1
        pointer[0] = start + 1
    elif wtype == 1:
        pointer[0] += 8
    elif wtype == 2:
        if raw_decode_uint32(pointer, end, &size):
            return -1
        if pointer[0]+size >= end:
            return -1
        pointer[0] += size
    elif wtype == 5:
        pointer[0] += 4
    else:
        return -1
    return 0

# }}}

cdef object decode_uint32(char **pointer, char *end):
    cdef uint32_t result
    if raw_decode_uint32(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `uint32` at [{0}]")

    return result

cdef object decode_uint64(char **pointer, char *end):
    cdef uint64_t result
    if raw_decode_uint64(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `uint64` at [{0}]")

    return result

cdef object decode_int32(char **pointer, char *end, ):
    cdef int32_t result
    if raw_decode_uint32(pointer, end, <uint32_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `int32` at [{0}]")

    return result

cdef object decode_int64(char **pointer, char *end, ):
    cdef int64_t result
    if raw_decode_uint64(pointer, end, <uint64_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `int64` at [{0}]")

    return result

cdef object decode_sint32(char **pointer, char *end, ):
    cdef uint32_t result
    if raw_decode_uint32(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `sint32` at [{0}]")

    return <int32_t>((result >> 1) ^ (-<int32_t>(result & 1)))

cdef object decode_sint64(char **pointer, char *end, ):
    cdef uint64_t un
    if raw_decode_uint64(pointer, end, &un):
        raise makeDecodeError(pointer[0], "Can't decode value of type `sint64` at [{0}]")

    return <int64_t>((un >> 1) ^ (-<int64_t>(un & 1)))

cdef object decode_fixed32(char **pointer, char *end, ):
    cdef uint32_t result
    if raw_decode_fixed32(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `fixed32` at [{0}]")

    return result

cdef object decode_fixed64(char **pointer, char *end, ):
    cdef uint64_t result
    if raw_decode_fixed64(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `fixed64` at [{0}]")

    return result

cdef object decode_sfixed32(char **pointer, char *end, ):
    cdef int32_t result
    if raw_decode_fixed32(pointer, end, <uint32_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `sfixed32` at [{0}]")

    return result

cdef object decode_sfixed64(char **pointer, char *end, ):
    cdef int64_t result
    if raw_decode_fixed64(pointer, end, <uint64_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `sfixed64` at [{0}]")

    return result

cdef object decode_bytes(char **pointer, char *end, ):
    cdef char *result
    cdef uint64_t size
    cdef int ret = raw_decode_delimited(pointer, end, &result, &size)
    if ret==0:
        return PyBytes_FromStringAndSize(result, size)

    if ret == -1:
        raise makeDecodeError(pointer[0], "Can't decode size for value of type `bytes` at [{0}]")
    elif ret == -2:
        raise makeDecodeError(pointer[0], "Can't decode value of type `bytes` of size %d at [{0}]" % size)


cdef object decode_string(char **pointer, char *end, ):
    cdef char *result
    cdef uint64_t size
    cdef int ret = raw_decode_delimited(pointer, end, &result, &size)
    if ret==0:
        return PyUnicode_FromStringAndSize(result, size)

    if ret == -1:
        raise makeDecodeError(pointer[0], "Can't decode size for value of type `string` at [{0}]")
    elif ret == -2:
        raise makeDecodeError(pointer[0], "Can't decode value of type `string` of size %d at [{0}]" % size)

cdef object decode_float(char **pointer, char *end, ):
    cdef float result
    if raw_decode_fixed32(pointer, end, <uint32_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `float` at [{0}]")

    return result

cdef object decode_double(char **pointer, char *end, ):
    cdef double result
    if raw_decode_fixed64(pointer, end, <uint64_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `double` at [{0}]")

    return result

cdef object decode_bool(char **pointer, char *end, ):
    cdef char* start = pointer[0]
    pointer[0] = start + 1

    return <bint>start[0]

# }}}

# {{{ encoding

cdef inline int raw_encode_uint32(bytearray array, uint32_t n) except -1:
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    bytearray_reserve(array, size + 10)
    cdef char *buff = array.ob_bytes + size

    if 0!=n:
        while True:
            rem = <char>(n & 0x7f)
            n = n>>7
            if 0==n:
                buff[0] = <char> rem
                buff+=1
                break
            else:
                rem = rem | 0x80
                buff[0] = <char> rem
                buff+=1
    else:
        buff[0] = '\0'
        buff+=1

    cdef Py_ssize_t ss = buff - array.ob_bytes
    array.ob_size = ss
    return 0

cdef inline encode_uint32(bytearray array, object value):
    raw_encode_uint32(array, value)

cdef inline encode_int32(bytearray array, object value):
    cdef int32_t n = value
    raw_encode_uint32(array, <uint32_t>n)

cdef inline encode_sint32(bytearray array, object value):
    cdef int32_t n = value
    cdef uint32_t un = (n << 1) ^ (n >> 31)

    raw_encode_uint32(array, un)

cdef inline int raw_encode_uint64(bytearray array, uint64_t n) except -1:
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    bytearray_reserve(array, size + 20)
    cdef char *buff = array.ob_bytes + size

    if 0!=n:
        while True:
            rem = <char>(n & 0x7f)
            n = n>>7
            if 0==n:
                buff[0] = <char> rem
                buff+=1
                break
            else:
                rem = rem | 0x80
                buff[0] = <char> rem
                buff+=1
    else:
        buff[0] = '\0'
        buff+=1
    array.ob_size = buff - array.ob_bytes
    return 0

cdef inline encode_uint64(bytearray array, object value):
    raw_encode_uint64(array, value)

cdef inline encode_int64(bytearray array, object value):
    cdef int64_t n = value
    raw_encode_uint64(array, <uint64_t>n)

cdef inline encode_sint64(bytearray array, object value):
    cdef int64_t n = value
    cdef uint64_t un = (n<<1) ^ (n>>63)
    raw_encode_uint64(array, un)

cdef inline int raw_encode_fixed32(bytearray array, uint32_t n) except -1:
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    bytearray_resize(array, size + 4)
    cdef char *buff = array.ob_bytes + size
    cdef int i

    for i from 0 <= i < 4:
        rem = n & 0xff
        n = n >> 8
        buff[0] = <char> rem
        buff += 1

    return 0

cdef inline encode_fixed32(bytearray array, object value):
    raw_encode_fixed32(array, value)

cdef inline encode_sfixed32(bytearray array, object value):
    cdef int32_t n = value
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    bytearray_resize(array, size + 4)
    cdef char *buff = array.ob_bytes + size
    cdef int i

    for i from 0 <= i < 4:
        rem = n & 0xff
        n = n >> 8
        buff[0] = <char> rem
        buff += 1

cdef inline int raw_encode_fixed64(bytearray array, uint64_t n) except -1:
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    bytearray_resize(array, size + 8)
    cdef char *buff = array.ob_bytes + size
    cdef int i

    for i from 0 <= i < 8:
        rem = n & 0xff
        n = n >> 8
        buff[0] = <char> rem
        buff += 1

    return 0

cdef inline encode_fixed64(bytearray array, object value):
    raw_encode_fixed64(array, value)

cdef inline encode_sfixed64(bytearray array, object value):
    cdef int64_t n = value
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    bytearray_resize(array, size + 8)
    cdef char *buff = array.ob_bytes + size
    cdef int i

    for i from 0 <= i < 8:
        rem = n & 0xff
        n = n >> 8
        buff[0] = <char> rem
        buff += 1

cdef inline encode_bytes(bytearray array, object n):
    cdef Py_ssize_t len = PySequence_Length(n)
    raw_encode_uint64(array, len)
    PySequence_InPlaceConcat(array, n)

cdef inline encode_string(bytearray array, object n):
    cdef object encoded = PyUnicode_AsUTF8String(n)
    cdef Py_ssize_t len = PySequence_Length(encoded)
    raw_encode_uint64(array, len)
    PySequence_InPlaceConcat(array, encoded)

cdef inline encode_bool(bytearray array, object value):
    cdef bint b = value
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    bytearray_resize(array, size + 1)
    cdef char *buff = array.ob_bytes + size
    buff[0] = b

cdef inline encode_float(bytearray array, object value):
    cdef float f = value
    raw_encode_fixed32(array, (<uint32_t*>&f)[0])

cdef inline encode_double(bytearray array, object value):
    cdef double d = value
    raw_encode_fixed64(array, (<uint64_t*>&d)[0])

cdef inline encode_type(bytearray array, unsigned char wire_type, uint32_t index):
    raw_encode_uint32(array, index<<3|wire_type)

# }}}
