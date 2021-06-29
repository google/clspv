// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


void kernel __attribute__((reqd_work_group_size(42, 13, 5))) foo(global uint* a)
{
  a[0] = get_local_size(0);
  a[1] = get_local_size(1);
  a[2] = get_local_size(2);
  a[3] = get_local_size(3);
}

void kernel __attribute__((reqd_work_group_size(42, 13, 5))) bar(global uint* a)
{
  a[0] = get_local_size(0);
  a[1] = get_local_size(1);
  a[2] = get_local_size(2);
  a[3] = get_local_size(3);
}

// CHECK:  OpEntryPoint GLCompute [[_20:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_32:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpExecutionMode [[_20]] LocalSize 42 13 5
// CHECK:  OpExecutionMode [[_32]] LocalSize 42 13 5
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG:  [[_uint_42:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 42
// CHECK-DAG:  [[_uint_13:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 13
// CHECK-DAG:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK-DAG:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG:  [[_gl_WorkGroupSize]] = OpConstantComposite [[_v3uint]] [[_uint_42]] [[_uint_13]] [[_uint_5]]
// CHECK:  [[_20]] = OpFunction
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_23]] 0
// CHECK:  OpStore {{.*}} [[_24]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_25]] 1
// CHECK:  OpStore {{.*}} [[_26]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_28]] 2
// CHECK:  OpStore {{.*}} [[_29]]
// CHECK:  OpStore {{.*}} [[_uint_1]]
// CHECK:  [[_32]] = OpFunction
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_35]] 0
// CHECK:  OpStore {{.*}} [[_36]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_37]] 1
// CHECK:  OpStore {{.*}} [[_38]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_40]] 2
// CHECK:  OpStore {{.*}} [[_41]]
// CHECK:  OpStore {{.*}} [[_uint_1]]
