// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[__original_id_1:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK:     %[[__original_id_19:[0-9]+]] = OpLoad %[[ushort]]
// CHECK:     %[[__original_id_20:[0-9]+]] = OpLoad %[[ushort]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpExtInst %[[ushort]] %[[__original_id_1]] SMin %[[__original_id_19]] %[[__original_id_20]]
// CHECK:     OpStore {{.*}} %[[__original_id_21]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global short* a, global short* b, global short* c)
{
    *a = min(*b, *c);
}

