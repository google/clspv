// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[glsl_ext:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_lo:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 7
// CHECK-DAG: %[[uint_hi:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 42
// CHECK:     OpExtInst %[[uint]] %[[glsl_ext]] SClamp {{.*}} %[[uint_lo]] %[[uint_hi]]

kernel void test_clamp(global int* out, global int* in)
{
    *out = clamp(*in, (int)7, (int)42);
}

