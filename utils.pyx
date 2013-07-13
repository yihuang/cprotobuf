from cpython cimport *
from libc.stdint cimport *

# {{{ definitions

cdef extern from "bytearrayobject.h":

    ctypedef class __builtin__.bytearray [object PyByteArrayObject]:
        cdef Py_ssize_t ob_alloc
        cdef char *ob_bytes
        cdef Py_ssize_t ob_size

cdef extern from "Python.h":
    bint PyByteArray_Resize(object bytearray, Py_ssize_t len)
    char* PyByteArray_AS_STRING(object bytearray)
    Py_ssize_t PyByteArray_GET_SIZE(object bytearray)
    object PyUnicode_FromStringAndSize(char *buff, Py_ssize_t len)
    Py_ssize_t Py_SIZE(object)

ctypedef object(*Decoder)(char **pointer, char *end)
ctypedef void(*Encoder)(bytearray array, object value)

class InternalDecodeError(Exception):
    pass

cdef inline object makeDecodeError(char* pointer, char* message):
    cdef uint64_t locator = <uint64_t>pointer
    return InternalDecodeError(PyLong_FromUnsignedLongLong(locator), message)

cdef inline int bytearray_reserve(bytearray ba, Py_ssize_t size):
    cdef Py_ssize_t alloc = ba.ob_alloc
    cdef Py_ssize_t tmp
    if size <= alloc:
        return 0

    if (size <= alloc * 1.125):
        if size < 9:
            tmp = 3
        else:
            tmp = 6
        alloc = size + (size >> 3) + tmp
    else:
        alloc = size + 1

    cdef void *sval = PyMem_Realloc(ba.ob_bytes, alloc)
    if sval == NULL:
        PyErr_NoMemory()
        return -1
    ba.ob_bytes = <char*>sval
    ba.ob_alloc = alloc
    return 0

# }}}

# {{{ decoding

# {{{ raw stuff

cdef inline int raw_decode_uint32(char **start, char *end, uint32_t *result) nogil:
    cdef uint32_t value = 0
    cdef uint32_t byte
    cdef char *pointer = start[0]
    cdef int counter = 0

    if pointer < end and <uint8_t>pointer[0] < 0x80:
        start[0] += 1
        result[0] = pointer[0]
        return 0

    while True:
        if pointer == end:
            return -1
        byte = pointer[0]
        value |= (byte & 0x7f) << counter
        if byte & 0x80 == 0:
            break
        counter+=7
        pointer+=1
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
    if start+size[0] >= end:
        return -1

    result[0] = start
    pointer[0] = start+size[0]
    return 0
# }}}

cdef object decode_uint32(char **pointer, char *end):
    cdef uint32_t result
    if raw_decode_uint32(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `uint32` at [{0}]")

    return PyLong_FromUnsignedLong(result)

cdef object decode_uint64(char **pointer, char *end):
    cdef uint64_t result
    if raw_decode_uint64(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `uint64` at [{0}]")

    return PyLong_FromUnsignedLongLong(result)

cdef object decode_int32(char **pointer, char *end, ):
    cdef int32_t result
    if raw_decode_uint32(pointer, end, <uint32_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `int32` at [{0}]")

    return PyInt_FromLong(result)

cdef object decode_int64(char **pointer, char *end, ):
    cdef int64_t result
    if raw_decode_uint64(pointer, end, <uint64_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `int64` at [{0}]")

    return PyLong_FromLongLong(result)

cdef object decode_sint32(char **pointer, char *end, ):
    cdef uint32_t result
    if raw_decode_uint32(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `sint32` at [{0}]")

    return PyInt_FromLong(<int32_t>((result >> 1) ^ (result << 31)))

cdef object decode_sint64(char **pointer, char *end, ):
    cdef uint64_t un
    if raw_decode_uint64(pointer, end, &un):
        raise makeDecodeError(pointer[0], "Can't decode value of type `sint64` at [{0}]")

    return PyLong_FromLongLong(<int64_t>((un>>1) ^ (un<<63)))

cdef object decode_fixed32(char **pointer, char *end, ):
    cdef uint32_t result
    if raw_decode_fixed32(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `fixed32` at [{0}]")

    return PyLong_FromUnsignedLong(result)

cdef object decode_fixed64(char **pointer, char *end, ):
    cdef uint64_t result
    if raw_decode_fixed64(pointer, end, &result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `fixed64` at [{0}]")

    return PyLong_FromUnsignedLongLong(result)

cdef object decode_sfixed32(char **pointer, char *end, ):
    cdef int32_t result
    if raw_decode_fixed32(pointer, end, <uint32_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `sfixed32` at [{0}]")

    return PyInt_FromLong(result)

cdef object decode_sfixed64(char **pointer, char *end, ):
    cdef int64_t result
    if raw_decode_fixed64(pointer, end, <uint64_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `sfixed64` at [{0}]")

    return PyLong_FromLongLong(result)

cdef object decode_bytes(char **pointer, char *end, ):
    cdef char *result
    cdef uint64_t size
    if raw_decode_delimited(pointer, end, &result, &size):
        raise makeDecodeError(pointer[0], "Can't decode value of type `bytes` at [{0}]")

    return PyBytes_FromStringAndSize(result, size)

cdef object decode_string(char **pointer, char *end, ):
    cdef char *result
    cdef uint64_t size
    if raw_decode_delimited(pointer, end, &result, &size):
        raise makeDecodeError(pointer[0], "Can't decode value of type `string` at [{0}]")

    return PyUnicode_FromStringAndSize(result, size)

cdef object decode_float(char **pointer, char *end, ):
    cdef float result
    if raw_decode_fixed32(pointer, end, <uint32_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `float` at [{0}]")

    return PyFloat_FromDouble(result)

cdef object decode_double(char **pointer, char *end, ):
    cdef double result
    if raw_decode_fixed64(pointer, end, <uint64_t*>&result):
        raise makeDecodeError(pointer[0], "Can't decode value of type `double` at [{0}]")

    return PyFloat_FromDouble(result)

cdef object decode_bool(char **pointer, char *end, ):
    cdef char* start = pointer[0]
    pointer[0] = start + 1

    return PyBool_FromLong(start[0])

# }}}

# {{{ encoding

cdef inline void encode_uint32(object array, object value):
    cdef uint32_t n = value
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    bytearray_reserve(array, size + 10)
    cdef char *buff = PyByteArray_AS_STRING(array) + size

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

    (<bytearray>array).ob_size = buff - PyByteArray_AS_STRING(array)

cdef inline void encode_int32(object array, object value):
    cdef int32_t n = value
    encode_uint32(array, <uint32_t>n)

cdef inline void encode_sint32(object array, object value):
    cdef int32_t n = value
    cdef uint32_t un = (n << 1) ^ (n >> 31)

    encode_uint32(array, un)

cdef inline void encode_uint64(object array, object value):
    cdef uint64_t n = value
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    bytearray_reserve(array, size + 20)
    cdef char *buff = PyByteArray_AS_STRING(array) + size

    if 0!=n:
        while( True):
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
    (<bytearray>array).ob_size = buff - PyByteArray_AS_STRING(array)

cdef inline void encode_int64(object array, object value):
    cdef int64_t n = value
    encode_uint64(array, <uint64_t>n)

cdef inline void encode_sint64(object array, object value):
    cdef int64_t n = value
    cdef uint64_t un = (n<<1) ^ (n>>63)
    encode_uint64(array, un)

cdef inline void encode_fixed32(object array, object value):
    cdef uint32_t n = value
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    PyByteArray_Resize(array, size + 4)
    cdef char *buff = PyByteArray_AS_STRING(array) + size
    cdef int i

    for i from 0 <= i < 4:
        rem = n & 0xff
        n = n >> 8
        buff[0] = <char> rem
        buff += 1

cdef inline void encode_sfixed32(object array, object value):
    cdef int32_t n = value
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    PyByteArray_Resize(array, size + 4)
    cdef char *buff = PyByteArray_AS_STRING(array) + size
    cdef int i

    for i from 0 <= i < 4:
        rem = n & 0xff
        n = n >> 8
        buff[0] = <char> rem
        buff += 1

cdef inline void encode_fixed64(object array, object value):
    cdef uint64_t n = value
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    PyByteArray_Resize(array, size + 8)
    cdef char *buff = PyByteArray_AS_STRING(array) + size
    cdef int i

    for i from 0 <= i < 8:
        rem = n & 0xff
        n = n >> 8
        buff[0] = <char> rem
        buff += 1

cdef inline void encode_sfixed64(object array, object value):
    cdef int64_t n = value
    cdef unsigned short int rem
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    PyByteArray_Resize(array, size + 8)
    cdef char *buff = PyByteArray_AS_STRING(array) + size
    cdef int i

    for i from 0 <= i < 8:
        rem = n & 0xff
        n = n >> 8
        buff[0] = <char> rem
        buff += 1

cdef inline void encode_bytes(object array, object n):
    cdef Py_ssize_t len = PySequence_Length(n)
    encode_uint64(array, len)
    cdef object spare = PySequence_InPlaceConcat(array, n)

cdef inline void encode_string(object array, object n):
    cdef object encoded = PyUnicode_AsUTF8String(n)
    cdef Py_ssize_t len = PySequence_Length(encoded)
    encode_uint64(array, len)
    cdef object spare = PySequence_InPlaceConcat(array, encoded)

cdef inline void encode_bool(object array, object value):
    cdef int b = value
    cdef Py_ssize_t size = PyByteArray_GET_SIZE(array)
    PyByteArray_Resize(array, size + 1)
    cdef char *buff = PyByteArray_AS_STRING(array) + size

    buff[0] = <char> (b and 1)

cdef inline void encode_float(array, object value):
    cdef float f = value
    encode_fixed32(array, (<uint32_t*>&f)[0])

cdef inline void encode_double(array, object value):
    cdef double d = value
    encode_fixed64(array, (<uint64_t*>&d)[0])

cdef inline void encode_type(array, unsigned char t, uint32_t n):
    encode_uint32(array, n<<3|t)

# }}}
