// RUN: clspv -uniform-workgroup-size -global-offset %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpDecorate [[spec_id_x:%[a-zA-Z0-9_]+]] SpecId 3
// CHECK: OpDecorate [[spec_id_y:%[a-zA-Z0-9_]+]] SpecId 4
// CHECK: OpDecorate [[spec_id_z:%[a-zA-Z0-9_]+]] SpecId 5
// CHECK-DAG: [[uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[uint]] 3
// CHECK-DAG: [[bool:%[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: [[uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[spec_id_x]] = OpSpecConstant [[uint]] 0
// CHECK-DAG: [[spec_id_y]] = OpSpecConstant [[uint]] 0
// CHECK-DAG: [[spec_id_z]] = OpSpecConstant [[uint]] 0
// CHECK-DAG: [[const:%[a-zA-Z0-9_]+]] = OpSpecConstantComposite [[v3uint]] [[spec_id_x]] [[spec_id_y]] [[spec_id_z]]
// CHECK-DAG: [[var_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[v3uint]]
// CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[uint]]
// CHECK: [[var:%[a-zA-Z0-9_]+]] = OpVariable [[var_ptr]] Private
// CHECK: [[param:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[uint]]
// CHECK: [[less:%[a-zA-Z0-9_]+]] = OpULessThan [[bool]] [[param]] [[uint_3]]
// CHECK: [[select:%[a-zA-Z0-9_]+]] = OpSelect [[uint]] [[less]] [[param]] [[uint_0]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] [[var]] [[select]]
// CHECK: [[load:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] [[gep]]
// CHECK: [[select2:%[a-zA-Z0-9_]+]] = OpSelect [[uint]] [[less]] [[load]] [[uint_0]]
// CHECK: OpReturnValue [[select2]]

void kernel __attribute__((reqd_work_group_size(1,1,1))) test(global int *out) {
    out[0] = get_global_offset(out[1]);
}

