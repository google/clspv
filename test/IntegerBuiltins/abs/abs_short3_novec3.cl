// RUN: clspv  %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[__original_id_1:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v4ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 4
// CHECK:     %[[__original_id_18:[0-9]+]] = OpLoad %[[v4ushort]]
// CHECK:     %[[__original_id_19:[0-9]+]] = OpExtInst %[[v4ushort]] %[[__original_id_1]] SAbs %[[__original_id_18]]
// CHECK:     OpStore {{.*}} %[[__original_id_19]]

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ushort3* a, global short3* b)
{
    *a = abs(*b);
}

