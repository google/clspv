// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel memcpy_from_constant(global float* result) {
  const float array[] = {-2.0f, -1.0f, 0.0f, 1.0f, 2.0f};
  for (size_t i = 0; i < 5; ++i) {
    result[i] = array[i];
  }
}

// CHECK: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[rta_float:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[float]]
// CHECK: [[struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[rta_float]]
// CHECK: [[ptr_ssbo_struct:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[struct]]
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[uint_5:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 5
// CHECK: [[float_array:%[a-zA-Z0-9_]+]] = OpTypeArray [[float]] [[uint_5]]
// CHECK: [[ptr_private_array:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[float_array]]
// CHECK: [[ptr_private_float:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[float]]
// CHECK: [[ptr_ssbo_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[float]]
// CHECK: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK: [[uint_4:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4
// CHECK: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2
// CHECK: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK: [[const_array:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_private_array]] Private
// CHECK: [[ssbo:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_ssbo_struct]] StorageBuffer
// CHECK: [[priv_gep0:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_private_float]] [[const_array]] [[uint_0]]
// CHECK: [[ssbo_gep0:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo_float]] [[ssbo]] [[uint_0]] [[uint_0]]
// CHECK: OpCopyMemory [[ssbo_gep0]] [[priv_gep0]] Aligned 4
// CHECK: [[priv_gep1:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_private_float]] [[const_array]] [[uint_1]]
// CHECK: [[ssbo_gep1:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo_float]] [[ssbo]] [[uint_0]] [[uint_1]]
// CHECK: OpCopyMemory [[ssbo_gep1]] [[priv_gep1]] Aligned 4
// CHECK: [[priv_gep2:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_private_float]] [[const_array]] [[uint_2]]
// CHECK: [[ssbo_gep2:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo_float]] [[ssbo]] [[uint_0]] [[uint_2]]
// CHECK: OpCopyMemory [[ssbo_gep2]] [[priv_gep2]] Aligned 4
// CHECK: [[priv_gep3:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_private_float]] [[const_array]] [[uint_3]]
// CHECK: [[ssbo_gep3:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo_float]] [[ssbo]] [[uint_0]] [[uint_3]]
// CHECK: OpCopyMemory [[ssbo_gep3]] [[priv_gep3]] Aligned 4
// CHECK: [[priv_gep4:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_private_float]] [[const_array]] [[uint_4]]
// CHECK: [[ssbo_gep4:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo_float]] [[ssbo]] [[uint_0]] [[uint_4]]
// CHECK: OpCopyMemory [[ssbo_gep4]] [[priv_gep4]] Aligned 4
