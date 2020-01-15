// RUN: clspv -work-dim -descriptormap=%t.dmap %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck --check-prefix=DMAP %s < %t.dmap
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// DMAP: pushconstant,name,dimensions,offset,0,size,4

// CHECK:     OpMemberDecorate %[[_struct_3:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_3]] Block
// CHECK:     OpMemberDecorate %[[_struct_9:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_9]] Block
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_struct_9]] = OpTypeStruct %[[uint]]
// CHECK-DAG: %[[_ptr_PushConstant__struct_9:[0-9a-zA-Z_]+]] = OpTypePointer PushConstant %[[_struct_9]]
// CHECK-DAG: %[[_ptr_PushConstant_uint:[0-9a-zA-Z_]+]] = OpTypePointer PushConstant %[[uint]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[__original_id_13:[0-9]+]] = OpVariable %[[_ptr_PushConstant__struct_9]] PushConstant
// CHECK:     %[[__original_id_18:[0-9]+]] = OpAccessChain %[[_ptr_PushConstant_uint]] %[[__original_id_13]] %[[uint_0]]
// CHECK:     %[[__original_id_19:[0-9]+]] = OpLoad %[[uint]] %[[__original_id_18]]
// CHECK:     OpStore {{.*}} %[[__original_id_19]]

void kernel __attribute__((reqd_work_group_size(1,1,1))) test(global int *out) {
    out[0] = get_work_dim();
}

