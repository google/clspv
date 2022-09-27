// RUN: clspv -cl-std=CL2.0 -global-offset %s -o %t.spv -inline-entry-points -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t.spv -o %t.dmap
// RUN: FileCheck --check-prefix=DMAP %s < %t.dmap
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// DMAP: pushconstant,name,global_offset,offset,0,size,12
// DMAP: pushconstant,name,enqueued_local_size,offset,16,size,12

// CHECK:     OpMemberDecorate %[[_struct_10:[0-9a-zA-Z_]+]] 1 Offset 16
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[_struct_10]] = OpTypeStruct %[[v3uint]] %[[v3uint]]
// CHECK-DAG: %[[_ptr_PushConstant__struct_10:[0-9a-zA-Z_]+]] = OpTypePointer PushConstant %[[_struct_10]]
// CHECK-DAG: %[[_ptr_PushConstant_uint:[0-9a-zA-Z_]+]] = OpTypePointer PushConstant %[[uint]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_15:[0-9]+]] = OpVariable %[[_ptr_PushConstant__struct_10]] PushConstant
// CHECK:     %[[__original_id_20:[0-9]+]] = OpAccessChain %[[_ptr_PushConstant_uint]] %[[__original_id_15]] %[[uint_1]] %[[uint_0]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[uint]] %[[__original_id_20]]
// CHECK:     OpStore {{.*}} %[[__original_id_21]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpAccessChain %[[_ptr_PushConstant_uint]] %[[__original_id_15]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[uint]] %[[__original_id_22]]
// CHECK:     OpStore {{.*}} %[[__original_id_23]]

void kernel __attribute__((reqd_work_group_size(1,1,1))) test(global int *out) {
    out[0] = get_enqueued_local_size(0);
    out[1] = get_global_offset(0);
}

