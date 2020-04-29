// RUN: clspv %s -o %t.spv -int8
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(char c) { }

// CHECK: OpCapability Int8
// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[char]]
// CHECK: [[block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[struct]]
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer PushConstant [[block]]
// CHECK: OpVariable [[ptr]] PushConstant
