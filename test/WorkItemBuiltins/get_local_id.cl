// RUN: clspv %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv



void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  a[get_local_id(b)] = get_local_id(3);
}

// CHECK:  OpDecorate [[_gl_LocalInvocationID:%[0-9a-zA-Z_]+]] BuiltIn LocalInvocationId
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_bool:%[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_gl_LocalInvocationID]] = OpVariable {{.*}} Input
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_uint]] [[_26:%[0-9a-zA-Z_]+]] [[_23]]
// CHECK:  OpStore {{.*}} [[_uint_0]]
// CHECK:  [[_26]] = OpFunction [[_uint]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpULessThan [[_bool]] [[_27]] [[_uint_3]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_29]] [[_27]] [[_uint_0]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_gl_LocalInvocationID]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_31]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_29]] [[_32]] [[_uint_0]]
// CHECK:  OpReturnValue [[_33]]
