// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[entry_id:%[a-zA-Z0-9_]*]] "dest_is_array"

// CHECK: OpDecorate

// Types:

// CHECK: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[ptr_sb_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[float]]
// CHECK: [[rtarr_float:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[float]]
// CHECK: [[st_rtarr_float:%[a-zA-Z0-9_]+]] = OpTypeStruct [[rtarr_float]]
// CHECK: [[ptr_sb_st_rtarr_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[st_rtarr_float]]

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[st_int:%[a-zA-Z0-9_]+]] = OpTypeStruct [[int]]
// CHECK: [[ptr_sb_st_int:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[st_int]]
// CHECK: [[ptr_sb_int:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[int]]

// CHECK: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[void_fn:%[a-zA-Z0-9_]+]] = OpTypeFunction [[void]]
// CHECK: [[n7:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 7
// CHECK: [[arr7_float:%[a-zA-Z0-9_]+]] = OpTypeArray [[float]] [[n7]]
// CHECK: [[ptr_arr7_float:%[a-zA-Z0-9_]+]] = OpTypePointer Function [[arr7_float]]
// CHECK: [[ptr_float:%[a-zA-Z0-9_]+]] = OpTypePointer Function [[float]]


// CHECK: [[n0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK: [[n4:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 4
// CHECK: [[n1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK: [[n2:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2
// CHECK: [[n3:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 3
// CHECK: [[n5:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 5
// CHECK: [[n6:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 6

// CHECK: [[var_A:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_sb_st_rtarr_float]] StorageBuffer
// CHECK: [[var_n:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_sb_st_int]] StorageBuffer
// CHECK: [[var_k:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_sb_st_int]] StorageBuffer


// CHECK: [[entry_id]] = OpFunction [[void]] None [[void_fn]]
// CHECK: OpLabel
// CHECK: [[n_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_int]] [[var_n]] [[n0]]
// CHECK: [[n:%[a-zA-Z0-9_]+]] = OpLoad [[int]] [[n_ptr]]
// CHECK: [[k_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_int]] [[var_k]] [[n0]]
// CHECK: [[k:%[a-zA-Z0-9_]+]] = OpLoad [[int]] [[k_ptr]]

// TODO(dneto): This variable declaration should appear earlier.
// CHECK: [[dest:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_arr7_float]] Function

// CHECK: [[A_0:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[n0]]
// CHECK: [[dest_0:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[dest]] [[n0]]

// CHECK: OpCopyMemory [[dest_0]] [[A_0]] Aligned 4
// CHECK: [[A_1:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[n1]]
// CHECK: [[dest_1:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[dest]] [[n1]]
// CHECK: OpCopyMemory [[dest_1]] [[A_1]] Aligned 4
// CHECK: [[A_2:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[n2]]
// CHECK: [[dest_2:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[dest]] [[n2]]
// CHECK: OpCopyMemory [[dest_2]] [[A_2]] Aligned 4
// CHECK: [[A_3:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[n3]]
// CHECK: [[dest_3:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[dest]] [[n3]]
// CHECK: OpCopyMemory [[dest_3]] [[A_3]] Aligned 4
// CHECK: [[A_4:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[n4]]
// CHECK: [[dest_4:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[dest]] [[n4]]
// CHECK: OpCopyMemory [[dest_4]] [[A_4]] Aligned 4
// CHECK: [[A_5:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[n5]]
// CHECK: [[dest_5:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[dest]] [[n5]]
// CHECK: OpCopyMemory [[dest_5]] [[A_5]] Aligned 4
// CHECK: [[A_6:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[n6]]
// CHECK: [[dest_6:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[dest]] [[n6]]
// CHECK: OpCopyMemory [[dest_6]] [[A_6]] Aligned 4

// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[dest]] [[k]]
// CHECK: [[value:%[a-zA-Z0-9_]+]] = OpLoad [[float]] [[ptr]]
// CHECK: [[out:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[n]]
// CHECK: OpStore [[out]] [[value]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
dest_is_array(global float *A, int n, int k) {
  float dest[7];
  for (int i = 0; i < 7; i++) {
    // Writing the whole array.
    dest[i] = A[i];
  }
  A[n] = dest[k];
}
