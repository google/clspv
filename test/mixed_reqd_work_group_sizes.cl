// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: OpDecorate [[x_id:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK-DAG: OpDecorate [[y_id:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK-DAG: OpDecorate [[z_id:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK-DAG: OpDecorate [[wgsize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK-DAG: [[x_id]] = OpSpecConstant {{.*}} 1
// CHECK-DAG: [[y_id]] = OpSpecConstant {{.*}} 1
// CHECK-DAG: [[z_id]] = OpSpecConstant {{.*}} 1
// CHECK-DAG: [[wgsize]] = OpSpecConstantComposite {{.*}} [[x_id]] [[y_id]] [[z_id]]

__attribute__((reqd_work_group_size(1,2,3)))
kernel void foo() { }

kernel void bar() { }

