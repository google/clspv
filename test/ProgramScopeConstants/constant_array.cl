// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

constant uint b[4] = {42, 13, 0, 5};

void kernel __attribute__((reqd_work_group_size(4, 1, 1))) foo(global uint* a)
{
  *a = b[get_local_id(0)];
}
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK:  [[__arr_uint_uint_4:%[0-9a-zA-Z_]+]] = OpTypeArray [[_uint]] [[_uint_4]]
// CHECK:  [[__ptr_Private__arr_uint_uint_4:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[__arr_uint_uint_4]]
// CHECK:  [[__ptr_Private_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_42:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 42
// CHECK:  [[_uint_13:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 13
// CHECK:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK:  [[_19:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__arr_uint_uint_4]] [[_uint_42]] [[_uint_13]] [[_uint_0]] [[_uint_5]]
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private__arr_uint_uint_4]] Private [[_19]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_21]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_28]]
