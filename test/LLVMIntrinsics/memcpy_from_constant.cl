// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel memcpy_from_constant(global float* result) {
  const float array[] = {-2.0f, -1.0f, 0.0f, 1.0f, 2.0f};
  for (size_t i = 0; i < 5; ++i) {
    result[i] = array[i];
  }
}

// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[rta_float:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[float]]
// CHECK-DAG: [[struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[rta_float]]
// CHECK-DAG: [[ptr_ssbo_struct:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[struct]]
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ptr_ssbo_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[float]]
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_4:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[ssbo:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_ssbo_struct]] StorageBuffer
// CHECK-DAG: [[float_n2:%[a-zA-Z0-9_]+]] = OpConstant [[float]] -2
// CHECK-DAG: [[float_n1:%[a-zA-Z0-9_]+]] = OpConstant [[float]] -1
// CHECK-DAG: [[float_0:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 0
// CHECK-DAG: [[float_1:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 1
// CHECK-DAG: [[float_2:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 2

// CHECK: [[ssbo_gep0:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo_float]] [[ssbo]] [[uint_0]] [[uint_0]]
// CHECK: OpStore [[ssbo_gep0]] [[float_n2]]
// CHECK: [[ssbo_gep1:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo_float]] [[ssbo]] [[uint_0]] [[uint_1]]
// CHECK: OpStore [[ssbo_gep1]] [[float_n1]]
// CHECK: [[ssbo_gep2:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo_float]] [[ssbo]] [[uint_0]] [[uint_2]]
// CHECK: OpStore [[ssbo_gep2]] [[float_0]]
// CHECK: [[ssbo_gep3:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo_float]] [[ssbo]] [[uint_0]] [[uint_3]]
// CHECK: OpStore [[ssbo_gep3]] [[float_1]]
// CHECK: [[ssbo_gep4:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo_float]] [[ssbo]] [[uint_0]] [[uint_4]]
// CHECK: OpStore [[ssbo_gep4]] [[float_2]]
