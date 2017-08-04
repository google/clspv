// RUN: clspv %s -S -o %t.spvasm -cluster-pod-kernel-args
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 37
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[foo:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpExecutionMode [[foo]] LocalSize 1 1 1

// CHECK: OpDecorate [[rtarr_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[st_rtarr_float:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[st_rtarr_float:%[a-zA-Z0-9_]+]] Block

// CHECK: OpMemberDecorate [[podty:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[podty]] 1 Offset 4
// CHECK: OpMemberDecorate [[st_podty:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[st_podty]] Block

// CHECK: OpDecorate [[A:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[A]] Binding 0
// CHECK: OpDecorate [[B:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[B]] Binding 1
// CHECK: OpDecorate [[podargs:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[podargs]] Binding 2
// CHECK: OpDecorate [[sbptr_float:%[a-zA-Z0-9_]+]] ArrayStride 4

// CHECK: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[sbptr_float]] = OpTypePointer StorageBuffer [[float]]
// CHECK: [[rtarr_float]] = OpTypeRuntimeArray [[float]]
// CHECK: [[st_rtarr_float]] = OpTypeStruct [[rtarr_float]]
// CHECK: [[sbptr_st_rtarr_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[st_rtarr_float]]

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[podty]] = OpTypeStruct [[float]] [[uint]]
// CHECK: [[st_podty]] = OpTypeStruct [[podty]]
// CHECK: [[sbptr_st_podty:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[st_podty]]
// CHECK: [[sbptr_podty:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[podty]]

// CHECK: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[void_fn:%[a-zA-Z0-9_]+]] = OpTypeFunction [[void]]
// CHECK: [[fooinner_fnty:%[a-zA-Z0-9_]+]] = OpTypeFunction [[void]] [[sbptr_float]] [[float]] [[sbptr_float]] [[uint]]
// CHECK: [[zero:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0

// CHECK: [[A]] = OpVariable [[sbptr_st_rtarr_float]] StorageBuffer
// CHECK: [[B]] = OpVariable [[sbptr_st_rtarr_float]] StorageBuffer
// CHECK: [[podargs]] = OpVariable [[sbptr_st_podty]] StorageBuffer

// The inner function.
// CHECK: [[fooinner:%[a-zA-Z0-9_]+]] = OpFunction [[void]] None [[fooinner_fnty]]
// CHECK: [[Aparm:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[sbptr_float]]
// CHECK: [[fparm:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[float]]
// CHECK: [[Bparm:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[sbptr_float]]
// CHECK: [[nparm:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[uint]]
// CHECK: [[fooinner_entry:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[B_n:%[a-zA-Z0-9_]+]] = OpPtrAccessChain [[sbptr_float]] [[Bparm]] [[nparm]]
// CHECK: [[Bval:%[a-zA-Z0-9_]+]] = OpLoad [[float]] [[B_n]]
// CHECK: [[sum:%[a-zA-Z0-9_]+]] = OpFAdd [[float]] [[Bval]] [[fparm]]
// CHECK: [[A_n:%[a-zA-Z0-9_]+]] = OpPtrAccessChain [[sbptr_float]] [[Aparm]] [[nparm]]
// CHECK: OpStore [[A_n]] [[sum]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

// The wrapper kernel.
// CHECK: [[foo]] = OpFunction [[void]] None [[void_fn]]
// CHECK: [[foo_entry:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[A_base:%[a-zA-Z0-9_]+]] = OpAccessChain [[sbptr_float]] [[A]] [[zero]] [[zero]]
// CHECK: [[B_base:%[a-zA-Z0-9_]+]] = OpAccessChain [[sbptr_float]] [[B]] [[zero]] [[zero]]
// CHECK: [[podargs_base:%[a-zA-Z0-9_]+]] = OpAccessChain [[sbptr_podty]] [[podargs]] [[zero]]
// CHECK: [[podargs_val:%[a-zA-Z0-9_]+]] = OpLoad [[podty]] [[podargs_base]]
// CHECK: [[f:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[float]] [[podargs_val]] 0
// CHECK: [[n:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[uint]] [[podargs_val]] 1
// CHECK: [[callresult:%[a-zA-Z0-9_]+]] = OpFunctionCall [[void]] [[fooinner]] [[A_base]] [[f]] [[B_base]] [[n]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* A, float f, global float* B, uint n)
{
  A[n] = B[n] + f;
}
