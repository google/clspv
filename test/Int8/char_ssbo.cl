// RUN: clspv %target %s -o %t.spv -int8
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global char* data) {
  *data = 0;
}

// CHECK: OpCapability Int8
// CHECK: OpDecorate [[rta:%[a-zA-Z0-9_]+]] ArrayStride 1
// CHECK: OpDecorate [[data:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[data]] Binding 0
// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[rta]] = OpTypeRuntimeArray [[char]]
// CHECK: [[block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[rta]]
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[block]]
// CHECK: [[data]] = OpVariable [[ptr]] StorageBuffer
