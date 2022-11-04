// RUN: clspv %target -work-dim %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t.spv -o %t.dmap
// RUN: FileCheck --check-prefix=DMAP %s < %t.dmap
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// DMAP: spec_constant,work_dim,spec_id,3

// CHECK:     OpDecorate [[const:%[a-zA-Z0-9_]+]] SpecId 3
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[int]]
// CHECK-DAG: [[const]] = OpSpecConstant [[int]] 3
// CHECK:     [[var:%[a-zA-Z0-9_]+]] = OpVariable [[ptr]] Private [[const]]
// CHECK:     [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[int]] [[var]]
// CHECK:     OpStore {{.*}} [[ld]]

void kernel __attribute__((reqd_work_group_size(1,1,1))) test(global int *out) {
    out[0] = get_work_dim();
}

