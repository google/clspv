// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[glsl_ext:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[uchar_lo:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 7
// CHECK-DAG: %[[uchar_hi:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 42
// CHECK:     OpExtInst %[[uchar]] %[[glsl_ext]] UClamp {{.*}} %[[uchar_lo]] %[[uchar_hi]]

kernel void test_clamp(global uchar* out, global uchar* in)
{
    *out = clamp(*in, (uchar)7, (uchar)42);
}


