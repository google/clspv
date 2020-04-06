// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(uint a)
{
}
// CHECK:  OpMemberDecorate [[__struct_2:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_2]] Block
// CHECK:  OpDecorate [[_8:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_8]] Binding 0
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__struct_2]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_2:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_2]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_8]] = OpVariable [[__ptr_StorageBuffer__struct_2]] StorageBuffer
// CHECK:  [[_11:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_8]] [[_uint_0]]
// CHECK:  [[_12:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_11]]
