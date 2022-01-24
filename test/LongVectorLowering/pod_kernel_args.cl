// RUN: clspv %s -o %t.spv -long-vector
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(float16 a, char8 b){}

// CHECK-DAG: [[int:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[int_16:%[^ ]+]] = OpConstant [[int]] 16
// CHECK-DAG: [[float16:%[^ ]+]] = OpTypeArray [[float]] [[int_16]]
// CHECK-DAG: [[char:%[^ ]+]] = OpTypeInt 8 0
// CHECK-DAG: [[int_8:%[^ ]+]] = OpConstant [[int]] 8
// CHECK-DAG: [[char8:%[^ ]+]] = OpTypeArray [[char]] [[int_8]]
// CHECK-DAG: [[struct15:%[^ ]+]] = OpTypeStruct [[float16]] [[char8]]
// CHECK-DAG: [[struct16:%[^ ]+]] = OpTypeStruct [[struct15]]
// CHECK-DAG: [[struct16_ptr:%[^ ]+]] = OpTypePointer PushConstant [[struct16]]
// CHECK-DAG: OpVariable [[struct16_ptr]] PushConstant
