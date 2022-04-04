// RUN: clspv %s -o %t.spv -hack-initializers -no-inline-single -uniform-workgroup-size
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// This is new, caused by -hack-initializers

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  a[get_global_size(b)] = get_global_size(3);
}

// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG:  [[_gl_WorkGroupSize]] = OpConstantComposite [[_v3uint]] [[_uint_1]] [[_uint_1]] [[_uint_1]]
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpVariable {{.*}} Private [[_gl_WorkGroupSize]]
// CHECK:  OpStore [[_21]] [[_gl_WorkGroupSize]]
