// RUN: clspv %s -o %t.spv -pod-ubo -cluster-pod-kernel-args=0 -physical-storage-buffers --arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void addKernel(int a, int b, __global int* out) {
   size_t id = get_global_id(0);
   out[id] = a + b;
}

// CHECK: OpMemberDecorate [[__struct_uint:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_uint]] Block
// CHECK: OpMemberDecorate [[__struct_ulong:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_ulong]] Block
// CHECK: OpDecorate [[_var_a:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_var_a]] Binding 0
// CHECK: OpDecorate [[_var_b:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_var_b]] Binding 1
// CHECK: OpDecorate [[_var_out:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_var_out]] Binding 2

// CHECK: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[__struct_uint]] = OpTypeStruct [[_uint]]
// CHECK: [[__ptr_Uniform__struct_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[__struct_uint]]
// CHECK: [[_ulong:%[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK: [[__struct_ulong]] = OpTypeStruct [[_ulong]]
// CHECK: [[__ptr_Uniform__struct_ulong:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[__struct_ulong]]
// CHECK: [[__ptr_Uniform_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[_uint]]
// CHECK: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[__ptr_Uniform_ulong:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[_ulong]]
// CHECK: [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK: [[_uint_8:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 8

// CHECK: [[_var_a]] = OpVariable [[__ptr_Uniform__struct_uint]] Uniform
// CHECK: [[_var_b]] = OpVariable [[__ptr_Uniform__struct_uint]] Uniform
// CHECK: [[_var_out]] = OpVariable [[__ptr_Uniform__struct_ulong]] Uniform

// CHECK: [[_gep_a:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Uniform_uint]] [[_var_a]] [[_uint_0]]
// CHECK: [[_load_a:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_gep_a]] Aligned 4
// CHECK: [[_gep_b:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Uniform_uint]] [[_var_b]] [[_uint_0]]
// CHECK: [[_load_b:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_gep_b]] Aligned 4
// CHECK: [[_gep_out:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Uniform_ulong]] [[_var_out]] [[_uint_0]]
// CHECK: [[_load_out:%[0-9a-zA-Z_]+]] = OpLoad [[_ulong]] [[_gep_out]] Aligned 8

// CHECK: OpExtInst %void %{{[0-9a-zA-Z_]+}} ArgumentPodUniform %{{[0-9a-zA-Z_]+}} [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_4]] %{{[0-9a-zA-Z_]+}}
// CHECK: OpExtInst %void %{{[0-9a-zA-Z_]+}} ArgumentPodUniform %{{[0-9a-zA-Z_]+}} [[_uint_1]] [[_uint_0]] [[_uint_1]] [[_uint_0]] [[_uint_4]] %{{[0-9a-zA-Z_]+}}
// CHECK: OpExtInst %void %{{[0-9a-zA-Z_]+}} ArgumentPointerUniform %{{[0-9a-zA-Z_]+}} [[_uint_2]] [[_uint_0]] [[_uint_2]] [[_uint_0]] [[_uint_8]] %{{[0-9a-zA-Z_]+}}
