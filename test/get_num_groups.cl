// RUN: clspv %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv



void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  a[get_num_groups(b)] = get_num_groups(3);
}

// CHECK:  OpDecorate [[_gl_NumWorkGroups:%[0-9a-zA-Z_]+]] BuiltIn NumWorkgroups
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_bool:%[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_gl_NumWorkGroups]] = OpVariable {{.*}} Input
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_uint]] [[_27:%[0-9a-zA-Z_]+]] [[_24]]
// CHECK:  OpStore {{.*}} [[_uint_1]]
// CHECK:  [[_27]] = OpFunction [[_uint]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpULessThan [[_bool]] [[_28]] [[_uint_3]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_30]] [[_28]] [[_uint_0]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_gl_NumWorkGroups]] [[_31]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_30]] [[_33]] [[_uint_1]]
// CHECK:  OpReturnValue [[_34]]
