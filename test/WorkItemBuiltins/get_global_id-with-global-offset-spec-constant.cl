// RUN: clspv -global-offset %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     OpDecorate [[spec_id_x:%[a-zA-Z0-9_]+]] SpecId 3
// CHECK:     OpDecorate [[spec_id_y:%[a-zA-Z0-9_]+]] SpecId 4
// CHECK:     OpDecorate [[spec_id_z:%[a-zA-Z0-9_]+]] SpecId 5
// CHECK:     OpDecorate [[gid:%[0-9a-zA-Z_]+]] BuiltIn GlobalInvocationId
// CHECK-DAG: [[uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[uint]] 3
// CHECK-DAG: [[_ptr_Input_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[v3uint]]
// CHECK-DAG: [[_ptr_Input_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[uint]]
// CHECK-DAG: [[spec_id_x]] = OpSpecConstant [[uint]] 0
// CHECK-DAG: [[spec_id_y]] = OpSpecConstant [[uint]] 0
// CHECK-DAG: [[spec_id_z]] = OpSpecConstant [[uint]] 0
// CHECK-DAG: [[const:%[a-zA-Z0-9_]+]] = OpSpecConstantComposite [[v3uint]] [[spec_id_x]] [[spec_id_y]] [[spec_id_z]]
// CHECK-DAG: [[offset_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[v3uint]]
// CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[uint]]
// CHECK-DAG: [[uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[gid]] = OpVariable [[_ptr_Input_v3uint]] Input
// CHECK-DAG: [[offset:%[a-zA-Z0-9_]+]] = OpVariable [[offset_ptr]] Private
// CHECK:     [[__original_id_22:%[0-9]+]] = OpAccessChain [[_ptr_Input_uint]] [[gid]] [[uint_0]]
// CHECK:     [[__original_id_23:%[0-9]+]] = OpLoad [[uint]] [[__original_id_22]]
// CHECK:     [[offset_gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] [[offset]] [[uint_0]]
// CHECK:     [[offset_load:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] [[offset_gep]]
// CHECK:     OpIAdd [[uint]] [[offset_load]] [[__original_id_23]]

void kernel __attribute__((reqd_work_group_size(1,1,1))) test(global int *out) {
    out[0] = get_global_id(0);
}

