// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[__original_id_1:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK:     %[[__original_id_18:[0-9]+]] = OpLoad %[[v2ulong]]
// CHECK:     %[[__original_id_19:[0-9]+]] = OpExtInst %[[v2ulong]] %[[__original_id_1]] SAbs %[[__original_id_18]]
// CHECK:     OpStore {{.*}} %[[__original_id_19]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ulong2* a, global long2* b)
{
    *a = abs(*b);
}

