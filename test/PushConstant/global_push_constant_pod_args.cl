// RUN: clspv %s -o %t.spv -cl-std=CL2.0 -global-offset -inline-entry-points -descriptormap=%t.map
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck --check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int* out, int a) {
  *out = a + get_global_id(0);
}

// MAP: pushconstant,name,global_offset,offset,0,size,12
// MAP: pushconstant,name,region_offset,offset,16,size,12
// MAP: kernel,foo,arg,out,argOrdinal,0
// MAP: kernel,foo,arg,a,argOrdinal,1,offset,32,argKind,pod_pushconstant,argSize,4

// CHECK-DAG: OpMemberDecorate [[pc_block:%[a-zA-Z0-9_]+]] 1 Offset 16
// CHECK-DAG: OpMemberDecorate [[pc_block]] 2 Offset 32
// CHECK-DAG: OpMemberDecorate [[pc_block]] 0 Offset 0
//     CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int3:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 3
// CHECK-DAG: [[pod_arg_struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[int]]
// CHECK-DAG: [[pc_block]] = OpTypeStruct [[int3]] [[int3]] [[pod_arg_struct]]
// CHECK-DAG: [[pc_block_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer PushConstant [[pc_block]]
// CHECK-DAG: [[int_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer PushConstant [[int]]
// CHECK-DAG: [[int_0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK-DAG: [[int_1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK-DAG: [[int_2:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2
// CHECK: [[pc_var:%[a-zA-Z0-9_]+]] = OpVariable [[pc_block_ptr]] PushConstant
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[int_ptr]] [[pc_var]] [[int_2]] [[int_0]]
// CHECK: [[ld_arg:%[a-zA-Z0-9_]+]] = OpLoad [[int]] [[gep]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[int_ptr]] [[pc_var]] [[int_1]] [[int_0]]
// CHECK: [[ld_offset:%[a-zA-Z0-9_]+]] = OpLoad [[int]] [[gep]]
// CHECK: [[add1:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] {{.*}} [[ld_arg]]
// CHECK: [[add2:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[add1]] [[ld_offset]]
