// RUN: clspv -uniform-workgroup-size  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     OpEntryPoint GLCompute %[[__original_id_4:[0-9]+]] "test"
// CHECK:     OpExecutionMode %[[__original_id_4]] LocalSize 1 2 3
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_3:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK:     %[[__original_id_4]] = OpFunction %[[void]] Const %[[__original_id_3]]

void kernel __attribute__((reqd_work_group_size(1,2,3))) test() {}

