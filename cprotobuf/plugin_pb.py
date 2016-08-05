# coding: utf-8
from cprotobuf import ProtoEntity, Field
# file: descriptor.proto
class SourceCodeInfo(ProtoEntity):
    location        = Field('SourceCodeInfo.Location',	1, repeated=True)

class UninterpretedOption(ProtoEntity):
    name            = Field('UninterpretedOption.NamePart',	2, repeated=True)
    identifier_value = Field('string',	3, required=False)
    positive_int_value = Field('uint64',	4, required=False)
    negative_int_value = Field('int64',	5, required=False)
    double_value    = Field('double',	6, required=False)
    string_value    = Field('bytes',	7, required=False)
    aggregate_value = Field('string',	8, required=False)

class EnumValueOptions(ProtoEntity):
    deprecated      = Field('bool',	1, required=False, default=False)
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class FieldOptions(ProtoEntity):
    # enum CType
    STRING=0
    CORD=1
    STRING_PIECE=2
    # enum JSType
    JS_NORMAL=0
    JS_STRING=1
    JS_NUMBER=2
    ctype           = Field('enum',	1, required=False, default=STRING)
    packed          = Field('bool',	2, required=False)
    jstype          = Field('enum',	6, required=False, default=JS_NORMAL)
    lazy            = Field('bool',	5, required=False, default=False)
    deprecated      = Field('bool',	3, required=False, default=False)
    weak            = Field('bool',	10, required=False, default=False)
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class MessageOptions(ProtoEntity):
    message_set_wire_format = Field('bool',	1, required=False, default=False)
    no_standard_descriptor_accessor = Field('bool',	2, required=False, default=False)
    deprecated      = Field('bool',	3, required=False, default=False)
    map_entry       = Field('bool',	7, required=False)
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
    java_string_check_utf8 = Field('bool',	27, required=False, default=False)
    optimize_for    = Field('enum',	9, required=False, default=SPEED)
    go_package      = Field('string',	11, required=False)
    cc_generic_services = Field('bool',	16, required=False, default=False)
    java_generic_services = Field('bool',	17, required=False, default=False)
    py_generic_services = Field('bool',	18, required=False, default=False)
    deprecated      = Field('bool',	23, required=False, default=False)
    cc_enable_arenas = Field('bool',	31, required=False, default=False)
    objc_class_prefix = Field('string',	36, required=False)
    csharp_namespace = Field('string',	37, required=False)
    javanano_use_deprecated_package = Field('bool',	38, required=False)
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class ServiceOptions(ProtoEntity):
    deprecated      = Field('bool',	33, required=False, default=False)
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class OneofDescriptorProto(ProtoEntity):
    name            = Field('string',	1, required=False)

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
    oneof_index     = Field('int32',	9, required=False)
    json_name       = Field('string',	10, required=False)
    options         = Field(FieldOptions,	8, required=False)

class EnumOptions(ProtoEntity):
    allow_alias     = Field('bool',	2, required=False)
    deprecated      = Field('bool',	3, required=False, default=False)
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
    oneof_decl      = Field(OneofDescriptorProto,	8, repeated=True)
    options         = Field(MessageOptions,	7, required=False)
    reserved_range  = Field('DescriptorProto.ReservedRange',	9, repeated=True)
    reserved_name   = Field('string',	10, repeated=True)

class GeneratedCodeInfo(ProtoEntity):
    annotation      = Field('GeneratedCodeInfo.Annotation',	1, repeated=True)

class MethodOptions(ProtoEntity):
    deprecated      = Field('bool',	33, required=False, default=False)
    uninterpreted_option = Field(UninterpretedOption,	999, repeated=True)

class MethodDescriptorProto(ProtoEntity):
    name            = Field('string',	1, required=False)
    input_type      = Field('string',	2, required=False)
    output_type     = Field('string',	3, required=False)
    options         = Field(MethodOptions,	4, required=False)
    client_streaming = Field('bool',	5, required=False, default=False)
    server_streaming = Field('bool',	6, required=False, default=False)

class ServiceDescriptorProto(ProtoEntity):
    name            = Field('string',	1, required=False)
    method          = Field(MethodDescriptorProto,	2, repeated=True)
    options         = Field(ServiceOptions,	3, required=False)

class FileDescriptorProto(ProtoEntity):
    name            = Field('string',	1, required=False)
    package         = Field('string',	2, required=False)
    dependency      = Field('string',	3, repeated=True)
    public_dependency = Field('int32',	10, repeated=True)
    weak_dependency = Field('int32',	11, repeated=True)
    message_type    = Field(DescriptorProto,	4, repeated=True)
    enum_type       = Field(EnumDescriptorProto,	5, repeated=True)
    service         = Field(ServiceDescriptorProto,	6, repeated=True)
    extension       = Field(FieldDescriptorProto,	7, repeated=True)
    options         = Field(FileOptions,	8, required=False)
    source_code_info = Field(SourceCodeInfo,	9, required=False)
    syntax          = Field('string',	12, required=False)

class FileDescriptorSet(ProtoEntity):
    file            = Field(FileDescriptorProto,	1, repeated=True)

# file: plugin.proto
class CodeGeneratorRequest(ProtoEntity):
    file_to_generate = Field('string',	1, repeated=True)
    parameter       = Field('string',	2, required=False)
    proto_file      = Field(FileDescriptorProto,	15, repeated=True)

class CodeGeneratorResponse_File(ProtoEntity):
    name            = Field('string',	1, required=False)
    insertion_point = Field('string',	2, required=False)
    content         = Field('string',	15, required=False)

class CodeGeneratorResponse(ProtoEntity):
    error           = Field('string',	1, required=False)
    file            = Field(CodeGeneratorResponse_File,	15, repeated=True)

