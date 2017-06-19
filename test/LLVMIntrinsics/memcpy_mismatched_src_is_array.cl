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
// CHECK: OpEntryPoint GLCompute [[entry_id:%[a-zA-Z0-9_]*]] "src_is_array"
// CHECK: OpExecutionMode [[entry_id]] LocalSize 1 1 1

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
// CHECK: [[f0:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 0
// CHECK: [[n1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK: [[f1:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 1
// CHECK: [[n2:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2
// CHECK: [[f2:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 2
// CHECK: [[n3:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 3
// CHECK: [[f3:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 3
// CHECK: [[n4:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 4
// CHECK: [[f4:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 4
// CHECK: [[n5:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 5
// CHECK: [[f5:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 5
// CHECK: [[n6:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 6
// CHECK: [[f6:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 6

// CHECK: [[var_A:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_sb_st_rtarr_float]] StorageBuffer
// CHECK: [[var_n:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_sb_st_int]] StorageBuffer
// CHECK: [[var_k:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_sb_st_int]] StorageBuffer


// CHECK: [[entry_id]] = OpFunction [[void]] None [[void_fn]]
// CHECK: OpLabel
// CHECK: [[n_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_int]] [[var_n]] [[n0]]
// CHECK: [[n:%[a-zA-Z0-9_]+]] = OpLoad [[int]] [[n_ptr]]

// TODO(dneto): This variable declaration should appear earlier.
// CHECK: [[src:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_arr7_float]] Function

// CHECK: [[src_0:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n0]]
// CHECK: OpStore [[src_0]] [[f0]]
// CHECK: [[src_1:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n1]]
// CHECK: OpStore [[src_1]] [[f1]]
// CHECK: [[src_2:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n2]]
// CHECK: OpStore [[src_2]] [[f2]]
// CHECK: [[src_3:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n3]]
// CHECK: OpStore [[src_3]] [[f3]]
// CHECK: [[src_4:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n4]]
// CHECK: OpStore [[src_4]] [[f4]]
// CHECK: [[src_5:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n5]]
// CHECK: OpStore [[src_5]] [[f5]]
// CHECK: [[src_6:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n6]]
// CHECK: OpStore [[src_6]] [[f6]]

// CHECK: [[src_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n0]]
// CHECK: [[index:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[n]] [[n0]]
// CHECK: [[A_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[index]]
// CHECK: OpCopyMemory [[A_elemp]] [[src_elemp]] Aligned 4
// CHECK: [[src_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n1]]
// CHECK: [[index:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[n]] [[n1]]
// CHECK: [[A_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[index]]
// CHECK: OpCopyMemory [[A_elemp]] [[src_elemp]] Aligned 4
// CHECK: [[src_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n2]]
// CHECK: [[index:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[n]] [[n2]]
// CHECK: [[A_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[index]]
// CHECK: OpCopyMemory [[A_elemp]] [[src_elemp]] Aligned 4
// CHECK: [[src_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n3]]
// CHECK: [[index:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[n]] [[n3]]
// CHECK: [[A_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[index]]
// CHECK: OpCopyMemory [[A_elemp]] [[src_elemp]] Aligned 4
// CHECK: [[src_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n4]]
// CHECK: [[index:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[n]] [[n4]]
// CHECK: [[A_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[index]]
// CHECK: OpCopyMemory [[A_elemp]] [[src_elemp]] Aligned 4
// CHECK: [[src_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n5]]
// CHECK: [[index:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[n]] [[n5]]
// CHECK: [[A_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[index]]
// CHECK: OpCopyMemory [[A_elemp]] [[src_elemp]] Aligned 4
// CHECK: [[src_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_float]] [[src]] [[n6]]
// CHECK: [[index:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[n]] [[n6]]
// CHECK: [[A_elemp:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_sb_float]] [[var_A]] [[n0]] [[index]]
// CHECK: OpCopyMemory [[A_elemp]] [[src_elemp]] Aligned 4

// CHECK-NOT: Op

// CHECK: OpReturn
// CHECK: OpFunctionEnd


void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
src_is_array(global float *A, int n, int k) {
  float src[7];
  for (int i = 0; i < 7; i++) {
    src[i] = i;
  }
  for (int i = 0; i < 7; i++) {
    A[n+i] = src[i]; // Reading whole array.
  }
}
