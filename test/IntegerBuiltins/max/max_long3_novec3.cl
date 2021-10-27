// RUN: clspv  %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[__original_id_1:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v4ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 4
// CHECK:     %[[__original_id_20:[0-9]+]] = OpLoad %[[v4ulong]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[v4ulong]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpExtInst %[[v4ulong]] %[[__original_id_1]] SMax %[[__original_id_20]] %[[__original_id_21]]
// CHECK:     OpStore {{.*}} %[[__original_id_22]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global long3* a, global long3* b, global long3* c)
{
    *a = max(*b, *c);
}

