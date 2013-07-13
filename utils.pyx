from cpython cimport *
from libc.stdint cimport *

# {{{ definitions

cdef extern from "Python.h":
    object PyUnicode_FromStringAndSize(char *buff, Py_ssize_t len)

class InternalDecodeError(Exception):
    pass

cdef inline object makeDecodeError(char* pointer, char* message):
    cdef uint64_t locator = <uint64_t>pointer
    return InternalDecodeError(PyLong_FromUnsignedLongLong(locator), message)

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

cdef inline int raw_decode_fixed64(char **pointer, char *end, uint64_t *result):
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

cdef inline int raw_decode_delimited(char **pointer, char *end, char **result, uint64_t *size):
    if raw_decode_uint64(pointer, end, size):
        return -1

    cdef char* start = pointer[0]
    if start+size[0] >= end:
        return -1

    result[0] = start
    pointer[0] = start+size[0]
    return 0
# }}}

cdef object decode_uint32(char **pointer, char *end):
    cdef uint32_t result
    if raw_decode_uint32(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `uint32` at [{0}]")

    return PyLong_FromUnsignedLong(result)

cdef object decode_uint64(char **pointer, char *end):
    cdef uint64_t result
    if raw_decode_uint64(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `uint64` at [{0}]")

    return PyLong_FromUnsignedLongLong(result)

cdef object decode_int32(char **pointer, char *end, ):
    cdef int32_t result
    if raw_decode_uint32(pointer, end, <uint32_t*>&result):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `int32` at [{0}]")

    return PyInt_FromLong(result)

cdef object decode_int64(char **pointer, char *end, ):
    cdef int64_t result
    if raw_decode_uint64(pointer, end, <uint64_t*>&result):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `int64` at [{0}]")

    return PyLong_FromLongLong(result)

cdef object decode_sint32(char **pointer, char *end, ):
    cdef uint32_t result
    if raw_decode_uint32(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `sint32` at [{0}]")

    return PyInt_FromLong(<int32_t>((result >> 1) ^ (result << 31)))

cdef object decode_sint64(char **pointer, char *end, ):
    cdef uint64_t un
    if raw_decode_uint64(pointer, end, &un):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `sint64` at [{0}]")

    return PyLong_FromLongLong(<int64_t>((un>>1) ^ (un<<63)))

cdef object decode_fixed32(char **pointer, char *end, ):
    cdef uint32_t result
    if raw_decode_fixed32(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `fixed32` at [{0}]")

    return PyLong_FromUnsignedLong(result)

cdef object decode_fixed64(char **pointer, char *end, ):
    cdef uint64_t result
    if raw_decode_fixed64(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `fixed64` at [{0}]")

    return PyLong_FromUnsignedLongLong(result)

cdef object decode_sfixed32(char **pointer, char *end, ):
    cdef int32_t result
    if raw_decode_fixed32(pointer, end, <uint32_t*>&result):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `sfixed32` at [{0}]")

    return PyInt_FromLong(result)

cdef object decode_sfixed64(char **pointer, char *end, ):
    cdef int64_t result
    if raw_decode_fixed64(pointer, end, <uint64_t*>&result):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `sfixed64` at [{0}]")

    return PyLong_FromLongLong(result)

cdef object decode_bytes(char **pointer, char *end, ):
    cdef char *result
    cdef uint64_t size
    if raw_decode_delimited(pointer, end, &result, &size):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `bytes` at [{0}]")

    return PyBytes_FromStringAndSize(result, size)

cdef object decode_string(char **pointer, char *end, ):
    cdef char *result
    cdef uint64_t size
    if raw_decode_delimited(pointer, end, &result, &size):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `string` at [{0}]")

    return PyUnicode_FromStringAndSize(result, size)

cdef object decode_float(char **pointer, char *end, ):
    cdef float result
    if raw_decode_fixed32(pointer, end, <uint32_t*>&result):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `float` at [{0}]")

    return PyFloat_FromDouble(result)

cdef object decode_double(char **pointer, char *end, ):
    cdef double result
    if raw_decode_fixed64(pointer, end, <uint64_t*>&result):
        raise makeDecodeError(pointer[0], "Can't deserialize value of type `double` at [{0}]")

    return PyFloat_FromDouble(result)

# }}}
