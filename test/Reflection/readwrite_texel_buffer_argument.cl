// RUN: clspv %s -o %t.spv -cl-std=CL2.0 -inline-entry-points --cl-kernel-arg-info
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env vulkan1.0

kernel void foo(read_write image1d_buffer_t im) { }

// CHECK: OpEntryPoint GLCompute [[foo:%[a-zA-Z0-9_]+]] "foo"
// CHECK-DAG: [[foo_name:%[a-zA-Z0-9_]+]] = OpString "foo"
// CHECK-DAG: [[im_name:%[a-zA-Z0-9_]+]] = OpString "im"
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int_0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK: [[kernel:%[a-zA-Z0-9_]+]] = OpExtInst [[void]] {{.*}} Kernel [[foo]] [[foo_name]]
// CHECK: [[info:%[a-zA-Z0-9_]+]] = OpExtInst [[void]] {{.*}} ArgumentInfo [[im_name]]
// CHECK: [[arg:%[a-zA-Z0-9_]+]] = OpExtInst [[void]] {{.*}} ArgumentStorageTexelBuffer [[kernel]] [[int_0]] [[int_0]] [[int_0]] [[info]]
