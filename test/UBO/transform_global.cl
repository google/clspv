// RUN: clspv %target -constant-args-ubo -inline-entry-points %s -o %t.spv -int8=0 -pod-ubo -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: clspv-reflection %t.spv -o %t2.map
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -constant-args-ubo -inline-entry-points %s -o %t.spv -int8=0 -pod-ubo -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: clspv-reflection %t.spv -o %t2.map
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct {
  int x __attribute__((aligned(16)));
} data_type;

__constant data_type c_var[2] = {{0}, {1}};

__kernel void foo(__global data_type *data, __constant data_type *c_arg,
                  int n) {
  data[n].x = c_arg[n].x + c_var[n].x;
}

//      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,c_arg,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo
// MAP-NEXT: kernel,foo,arg,n,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,pod_ubo

// CHECK-DAG: OpDecorate [[runtime:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK-DAG: OpMemberDecorate [[data_type:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK-DAG: OpMemberDecorate [[data_type]] 1 Offset 4
// CHECK-DAG: OpDecorate [[data:%[0-9a-zA-Z_]+]] Binding 0
// CHECK-DAG: OpDecorate [[data]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[c_arg:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG: OpDecorate [[c_arg]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[c_arg]] NonWritable
// CHECK-DAG: OpDecorate [[n:%[0-9a-zA-Z_]+]] Binding 2
// CHECK-DAG: OpDecorate [[n]] DescriptorSet 0
// CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[long:%[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: [[data_type]] = OpTypeStruct [[int]] [[int]]
// CHECK-DAG: [[runtime]] = OpTypeRuntimeArray [[data_type]]
// CHECK-DAG: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[runtime]]
// CHECK-DAG: [[data_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[struct]]
// CHECK-DAG: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
// CHECK-DAG: [[ubo_array:%[0-9a-zA-Z_]+]] = OpTypeArray [[data_type]] [[int_4096]]
// CHECK-DAG: [[ubo_struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[ubo_array]]
// CHECK-DAG: [[c_arg_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_struct]]
// CHECK-DAG: [[data_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[int]]
// CHECK-DAG: [[c_arg_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int]]
// CHECK-DAG: [[two:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2
// CHECK-DAG: [[array:%[0-9a-zA-Z_]+]] = OpTypeArray [[data_type]] [[two]]
// CHECK-DAG: [[c_var_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[array]]
// CHECK-DAG: [[c_var_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[int]]
// CHECK-DAG: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
// CHECK-DAG: [[zero_zero:%[0-9a-zA-Z_]+]] = OpConstantNull [[data_type]]
// CHECK-DAG: [[one:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 1
// CHECK-DAG: [[one_zero:%[0-9a-zA-Z_]+]] = OpConstantComposite [[data_type]] [[one]] [[zero]]
// CHECK-DAG: [[array_const:%[0-9a-zA-Z_]+]] = OpConstantComposite [[array]] [[zero_zero]] [[one_zero]]
// CHECK-DAG: [[c_var:%[0-9a-zA-Z_]+]] = OpVariable [[c_var_ptr]] Private [[array_const]]
// CHECK-DAG: [[data]] = OpVariable [[data_ptr]] StorageBuffer
//     CHECK: [[c_arg]] = OpVariable [[c_arg_ptr]] Uniform
//     CHECK: [[n_load:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[int]]
//  CHECK-64: [[n_load_long:%[0-9a-zA-Z_]+]] = OpSConvert [[long]] [[n_load]]
//  CHECK-64: [[c_arg_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[c_arg_ele_ptr]] [[c_arg]] [[zero]] [[n_load_long]] [[zero]]
//  CHECK-32: [[c_arg_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[c_arg_ele_ptr]] [[c_arg]] [[zero]] [[n_load]] [[zero]]
//     CHECK: [[c_load:%[0-9a-zA-Z_]+]] = OpLoad [[int]] [[c_arg_gep]]
//  CHECK-64: [[priv_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[c_var_ele_ptr]] [[c_var]] [[n_load_long]] [[zero]]
//  CHECK-32: [[priv_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[c_var_ele_ptr]] [[c_var]] [[n_load]] [[zero]]
//     CHECK: [[priv_load:%[0-9a-zA-Z_]+]] = OpLoad [[int]] [[priv_gep]]
//     CHECK: [[res:%[0-9a-zA-Z_]+]] = OpIAdd [[int]] [[priv_load]] [[c_load]]
//  CHECK-64: [[data_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[data_ele_ptr]] [[data]] [[zero]] [[n_load_long]] [[zero]]
//  CHECK-32: [[data_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[data_ele_ptr]] [[data]] [[zero]] [[n_load]] [[zero]]
//     CHECK: OpStore [[data_gep]] [[res]]
