// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[__original_id_1:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK:     %[[__original_id_17:[0-9]+]] = OpLoad %[[ushort]]
// CHECK:     %[[__original_id_18:[0-9]+]] = OpExtInst %[[ushort]] %[[__original_id_1]] SAbs %[[__original_id_17]]
// CHECK:     OpStore {{.*}} %[[__original_id_18]]


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ushort* a, global short* b)
{
    *a = abs(*b);
}

