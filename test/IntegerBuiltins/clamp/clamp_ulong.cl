// RUN: clspv %target  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[glsl_ext:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[ulong_lo:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 7
// CHECK-DAG: %[[ulong_hi:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 42
// CHECK:     OpExtInst %[[ulong]] %[[glsl_ext]] UClamp {{.*}} %[[ulong_lo]] %[[ulong_hi]]

kernel void test_clamp(global ulong* out, global ulong* in)
{
    *out = clamp(*in, (ulong)7, (ulong)42);
}

