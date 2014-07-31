# coding: utf-8
from cprotobuf import ProtoEntity, Field
# file: descriptor.proto
class Location(ProtoEntity):
    path            = Field('int32',	1, repeated=True, packed=True)
    span            = Field('int32',	2, repeated=True, packed=True)

class SourceCodeInfo(ProtoEntity):
    location        = Field(Location,	1, repeated=True)

class NamePart(ProtoEntity):
    name_part       = Field('string',	1)
    is_extension    = Field('bool',	2)

class UninterpretedOption(ProtoEntity):
    name            = Field(NamePart,	2, repeated=True)
    identifier_value = Field('string',	3, required=False)
    positive_int_value = Field('uint64',	4, required=False)
    negative_int_value = Field('int64',	5, required=False)
    double_value    = Field('double',	6, required=False)
    string_value    = Field('bytes',	7, required=False)
    aggregate_value = Field('string',	8, required=False)

class EnumValueOptions(ProtoEntity):
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class FieldOptions(ProtoEntity):
    # enum CType
    STRING=0
    CORD=1
    STRING_PIECE=2
    ctype           = Field('enum',	1, required=False, default=STRING)
    packed          = Field('bool',	2, required=False)
    deprecated      = Field('bool',	3, required=False, default=False)
    experimental_map_key = Field('string',	9, required=False)
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class MessageOptions(ProtoEntity):
    message_set_wire_format = Field('bool',	1, required=False, default=False)
    no_standard_descriptor_accessor = Field('bool',	2, required=False, default=False)
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class ExtensionRange(ProtoEntity):
    start           = Field('int32',	1, required=False)
    end             = Field('int32',	2, required=False)

class EnumValueDescriptorProto(ProtoEntity):
    name            = Field('string',	1, required=False)
    number          = Field('int32',	2, required=False)
    options         = Field(EnumValueOptions,	3, required=False)

class FileOptions(ProtoEntity):
    # enum OptimizeMode
    SPEED=1
    CODE_SIZE=2
    LITE_RUNTIME=3
    java_package    = Field('string',	1, required=False)
    java_outer_classname = Field('string',	8, required=False)
    java_multiple_files = Field('bool',	10, required=False, default=False)
    java_generate_equals_and_hash = Field('bool',	20, required=False, default=False)
    optimize_for    = Field('enum',	9, required=False, default=SPEED)
    cc_generic_services = Field('bool',	16, required=False, default=False)
    java_generic_services = Field('bool',	17, required=False, default=False)
    py_generic_services = Field('bool',	18, required=False, default=False)
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class ServiceOptions(ProtoEntity):
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class FieldDescriptorProto(ProtoEntity):
    # enum Type
    TYPE_DOUBLE=1
    TYPE_FLOAT=2
    TYPE_INT64=3
    TYPE_UINT64=4
    TYPE_INT32=5
    TYPE_FIXED64=6
    TYPE_FIXED32=7
    TYPE_BOOL=8
    TYPE_STRING=9
    TYPE_GROUP=10
    TYPE_MESSAGE=11
    TYPE_BYTES=12
    TYPE_UINT32=13
    TYPE_ENUM=14
    TYPE_SFIXED32=15
    TYPE_SFIXED64=16
    TYPE_SINT32=17
    TYPE_SINT64=18
    # enum Label
    LABEL_OPTIONAL=1
    LABEL_REQUIRED=2
    LABEL_REPEATED=3
    name            = Field('string',	1, required=False)
    number          = Field('int32',	3, required=False)
    label           = Field('enum',	4, required=False)
    type            = Field('enum',	5, required=False)
    type_name       = Field('string',	6, required=False)
    extendee        = Field('string',	2, required=False)
    default_value   = Field('string',	7, required=False)
    options         = Field(FieldOptions,	8, required=False)

class EnumOptions(ProtoEntity):
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class EnumDescriptorProto(ProtoEntity):
    name            = Field('string',	1, required=False)
    value           = Field(EnumValueDescriptorProto,	2, repeated=True)
    options         = Field(EnumOptions,	3, required=False)

class DescriptorProto(ProtoEntity):
    name            = Field('string',	1, required=False)
    field           = Field(FieldDescriptorProto,	2, repeated=True)
    extension       = Field(FieldDescriptorProto,	6, repeated=True)
    nested_type     = Field('DescriptorProto',	3, repeated=True)
    enum_type       = Field(EnumDescriptorProto,	4, repeated=True)
    extension_range = Field(ExtensionRange,	5, repeated=True)
    options         = Field(MessageOptions,	7, required=False)

class MethodOptions(ProtoEntity):
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class MethodDescriptorProto(ProtoEntity):
    name            = Field('string',	1, required=False)
    input_type      = Field('string',	2, required=False)
    output_type     = Field('string',	3, required=False)
    options         = Field(MethodOptions,	4, required=False)

class ServiceDescriptorProto(ProtoEntity):
    name            = Field('string',	1, required=False)
    method          = Field(MethodDescriptorProto,	2, repeated=True)
    options         = Field(ServiceOptions,	3, required=False)

class FileDescriptorProto(ProtoEntity):
    name            = Field('string',	1, required=False)
    package         = Field('string',	2, required=False)
    dependency      = Field('string',	3, repeated=True)
    message_type    = Field(DescriptorProto,	4, repeated=True)
    enum_type       = Field(EnumDescriptorProto,	5, repeated=True)
    service         = Field(ServiceDescriptorProto,	6, repeated=True)
    extension       = Field(FieldDescriptorProto,	7, repeated=True)
    options         = Field(FileOptions,	8, required=False)
    source_code_info = Field(SourceCodeInfo,	9, required=False)

class FileDescriptorSet(ProtoEntity):
    file            = Field(FileDescriptorProto,	1, repeated=True)

# file: plugin.proto
class CodeGeneratorRequest(ProtoEntity):
    file_to_generate = Field('string',	1, repeated=True)
    parameter       = Field('string',	2, required=False)
    proto_file      = Field(FileDescriptorProto,	15, repeated=True)

class File(ProtoEntity):
    name            = Field('string',	1, required=False)
    insertion_point = Field('string',	2, required=False)
    content         = Field('string',	15, required=False)

class CodeGeneratorResponse(ProtoEntity):
    error           = Field('string',	1, required=False)
    file            = Field(File,	15, repeated=True)

