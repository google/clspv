// RUN: clspv  %s -S -o %t.spvasm -int8
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[glsl_ext:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK:     %[[v3uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 3
// CHECK-DAG: %[[uchar_7:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 7
// CHECK-DAG: %[[lovec:[0-9]+]] = OpConstantComposite %[[v3uchar]] %[[uchar_7]] %[[uchar_7]] %[[uchar_7]]
// CHECK-DAG: %[[uchar_42:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 42
// CHECK-DAG: %[[hivec:[0-9]+]] = OpConstantComposite %[[v3uchar]] %[[uchar_42]] %[[uchar_42]] %[[uchar_42]]
// CHECK:     OpExtInst %[[v3uchar]] %[[glsl_ext]] UClamp {{.*}} %[[lovec]] %[[hivec]]

kernel void test_clamp(global uchar3* out, global uchar3* in)
{
    *out = clamp(*in, (uchar3)7, (uchar3)42);
}


