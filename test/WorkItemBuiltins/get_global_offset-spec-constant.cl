// RUN: clspv -global-offset %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t.spv -o %t.dmap
// RUN: FileCheck --check-prefix=DMAP %s < %t.dmap
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// DMAP: spec_constant,global_offset_x,spec_id,3
// DMAP: spec_constant,global_offset_y,spec_id,4
// DMAP: spec_constant,global_offset_z,spec_id,5

// CHECK: OpDecorate %[[spec_id_x:[a-zA-Z0-9_]+]] SpecId 3
// CHECK: OpDecorate %[[spec_id_y:[a-zA-Z0-9_]+]] SpecId 4
// CHECK: OpDecorate %[[spec_id_z:[a-zA-Z0-9_]+]] SpecId 5
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[spec_id_x]] = OpSpecConstant %[[uint]] 0
// CHECK-DAG: %[[spec_id_y]] = OpSpecConstant %[[uint]] 0
// CHECK-DAG: %[[spec_id_z]] = OpSpecConstant %[[uint]] 0
// CHECK-DAG: %[[spec_const:[a-zA-Z0-9_]+]] = OpSpecConstantComposite %[[v3uint]] %[[spec_id_x]] %[[spec_id_y]] %[[spec_id_z]]
// CHECK-DAG: %[[var_ptr:[a-zA-Z0-9_]+]] = OpTypePointer Private %[[v3uint]]
// CHECK-DAG: %[[ptr:[a-zA-Z0-9_]+]] = OpTypePointer Private %[[uint]]
// CHECK: %[[var:[a-zA-Z0-9_]+]] = OpVariable %[[var_ptr]] Private
// CHECK: %[[gep:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr]] %[[var]] %[[uint_0]]
// CHECK: %[[load:[a-zA-Z0-9_]+]] = OpLoad %[[uint]] %[[gep]]
// CHECK: OpStore {{.*}} %[[load]]

void kernel __attribute__((reqd_work_group_size(1,1,1))) test(global int *out) {
    out[0] = get_global_offset(0);
}

