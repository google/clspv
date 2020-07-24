// RUN: clspv -cl-std=CL2.0 -inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t.spv -o %t.dmap
// RUN: FileCheck --check-prefix=DMAP %s < %t.dmap
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// DMAP: pushconstant,name,global_size,offset,0,size,12

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[_struct_12:[0-9a-zA-Z_]+]] = OpTypeStruct %[[v3uint]]
// CHECK-DAG: %[[_ptr_PushConstant__struct_12:[0-9a-zA-Z_]+]] = OpTypePointer PushConstant %[[_struct_12]]
// CHECK-DAG: %[[_ptr_PushConstant_uint:[0-9a-zA-Z_]+]] = OpTypePointer PushConstant %[[uint]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[__original_id_16:[0-9]+]] = OpVariable %[[_ptr_PushConstant__struct_12]] PushConstant
// CHECK:     %[[__original_id_24:[0-9]+]] = OpAccessChain %[[_ptr_PushConstant_uint]] %[[__original_id_16]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpLoad %[[uint]] %[[__original_id_24]]
// CHECK:     OpStore {{.*}} %[[__original_id_25]]

void kernel __attribute__((reqd_work_group_size(1,1,1))) test(global int *out) {
    out[0] = get_global_size(0);
}

