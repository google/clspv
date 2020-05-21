// RUN: clspv %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv



void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  a[get_global_size(b)] = get_global_size(3);
}

// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_gl_NumWorkGroups:%[0-9a-zA-Z_]+]] BuiltIn NumWorkgroups
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_bool:%[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_gl_WorkGroupSize]] = OpConstantComposite [[_v3uint]] [[_uint_1]] [[_uint_1]] [[_uint_1]]
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpVariable {{.*}} Private [[_gl_WorkGroupSize]]
// CHECK:  [[_gl_NumWorkGroups]] = OpVariable {{.*}} Input
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_uint]] [[_31:%[0-9a-zA-Z_]+]] [[_28]]
// CHECK:  OpStore {{.*}} [[_uint_1]]
// CHECK:  [[_31]] = OpFunction [[_uint]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpULessThan [[_bool]] [[_32]] [[_uint_3]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_34]] [[_32]] [[_uint_0]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_21]] [[_35]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_36]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_gl_NumWorkGroups]] [[_35]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_38]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpIMul [[_uint]] [[_39]] [[_37]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_34]] [[_40]] [[_uint_1]]
// CHECK:  OpReturnValue [[_41]]
