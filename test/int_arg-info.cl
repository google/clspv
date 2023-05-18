// RUN: clspv %target %s -o %t.spv -cl-kernel-arg-info
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[arg1:%[^ ]+]] = OpString "v"
// CHECK-DAG: [[arg1_type:%[^ ]+]] = OpString "int"
// CHECK-DAG: [[arg2:%[^ ]+]] = OpString ""
// CHECK-DAG: [[arg2_type:%[^ ]+]] = OpString "int*"
// CHECK-DAG: [[arg3:%[^ ]+]] = OpString "b"
// CHECK-DAG: [[arg3_type:%[^ ]+]] = OpString "int*"
// CHECK-DAG: OpExtInst %void {{.*}} ArgumentInfo [[arg1]] [[arg1_type]]
// CHECK-DAG: OpExtInst %void {{.*}} ArgumentInfo [[arg2]] [[arg2_type]]
// CHECK-DAG: OpExtInst %void {{.*}} ArgumentInfo [[arg3]] [[arg3_type]]

kernel void k0(int v, local int *, global int* b){}
