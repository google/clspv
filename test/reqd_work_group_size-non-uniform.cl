// RUN: clspv -cl-std=CL2.0 -inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
//
// RUN: clspv -cl-arm-non-uniform-work-group-size %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     OpEntryPoint GLCompute %[[__original_id_16:[0-9]+]] "test"
// CHECK:     OpDecorate %[[gl_WorkGroupSize:[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:     OpDecorate %[[__original_id_11:[0-9]+]] SpecId 0
// CHECK:     OpDecorate %[[__original_id_12:[0-9]+]] SpecId 1
// CHECK:     OpDecorate %[[__original_id_13:[0-9]+]] SpecId 2
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_3:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[_ptr_Private_v3uint:[0-9a-zA-Z_]+]] = OpTypePointer Private %[[v3uint]]
// CHECK-DAG: %[[__original_id_11]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_12]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_13]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[gl_WorkGroupSize]] = OpSpecConstantComposite %[[v3uint]] %[[__original_id_11]] %[[__original_id_12]] %[[__original_id_13]]
// CHECK-DAG: %[[__original_id_15:[0-9]+]] = OpVariable %[[_ptr_Private_v3uint]] Private %[[gl_WorkGroupSize]]
// CHECK:     %[[__original_id_16]] = OpFunction %[[void]] Const %[[__original_id_3]]

void kernel __attribute__((reqd_work_group_size(1,2,3))) test() {}

