// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[glsl_ext:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[ushort_lo:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 7
// CHECK-DAG: %[[ushort_hi:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 42
// CHECK:     OpExtInst %[[ushort]] %[[glsl_ext]] UClamp {{.*}} %[[ushort_lo]] %[[ushort_hi]]

kernel void test_clamp(global ushort* out, global ushort* in)
{
    *out = clamp(*in, (ushort)7, (ushort)42);
}

