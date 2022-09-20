// RUN: clspv %s -o %t2.spv --enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t2.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t2.spv

kernel void bar(global float3* data) {
  global float3* tmp1 = &(data[3]);
  global float4* tmp2 = (global float4*)tmp1;
  *tmp2 = (float4)(0.0f,0.0f,0.0f,0.0f);
}

// CHECK-DAG: [[uint:%[0-9a-zA-Z_]*]] = OpTypeInt 32 0
// CHECK-DAG: [[float:%[0-9a-zA-Z_]*]] = OpTypeFloat 32
// CHECK-DAG: [[vec4:%[0-9a-zA-Z_]*]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[ptr_storage_buffer_vec4:%[0-9a-zA-Z_]*]] = OpTypePointer StorageBuffer [[vec4]]
// CHECK-DAG: [[uint_0:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 3
// CHECK-DAG: [[empty_vec4:%[0-9a-zA-Z_]*]] = OpConstantNull [[vec4]] 
// CHECK: [[vec4_ptr:%[0-9a-zA-Z_]*]] = OpAccessChain [[ptr_storage_buffer_vec4]] {{.*}} [[uint_0]] [[uint_3]]
// CHECK: OpStore [[vec4_ptr]] [[empty_vec4]]
