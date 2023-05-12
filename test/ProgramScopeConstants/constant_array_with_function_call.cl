// RUN: clspv %target %s -o %t.spv -no-inline-single -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -no-inline-single -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK
// RUN: spirv-val --target-env vulkan1.0 %t.spv


constant uint b[4] = {42, 13, 0, 5};

__attribute__((noinline))
uint bar(constant uint* a)
{
  return a[get_local_id(0)];
}

void kernel __attribute__((reqd_work_group_size(4, 1, 1))) foo(global uint* a)
{
  *a = bar(b);
}
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK-DAG:  [[__arr_uint_uint_4:%[0-9a-zA-Z_]+]] = OpTypeArray [[_uint]] [[_uint_4]]
// CHECK-DAG:  [[__ptr_Private__arr_uint_uint_4:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[__arr_uint_uint_4]]
// CHECK-DAG:  [[__ptr_Private_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_uint]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_uint_42:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 42
// CHECK-DAG:  [[_uint_13:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 13
// CHECK-DAG:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK-DAG:  [[_20:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__arr_uint_uint_4]] [[_uint_42]] [[_uint_13]] [[_uint_0]] [[_uint_5]]
// CHECK-DAG:  [[_22:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private__arr_uint_uint_4]] Private [[_20]]
// CHECK:  = OpFunction
