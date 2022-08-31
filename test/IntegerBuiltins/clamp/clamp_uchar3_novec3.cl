// RUN: clspv  %s -o %t.spv -int8 -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -vec3-to-vec4 --enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[glsl_ext:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK:     %[[v4uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 4
// CHECK-DAG: %[[uchar_7:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 7
// CHECK-DAG: %[[lovec:[0-9]+]] = OpConstantComposite %[[v4uchar]] %[[uchar_7]] %[[uchar_7]] %[[uchar_7]]
// CHECK-DAG: %[[uchar_42:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 42
// CHECK-DAG: %[[hivec:[0-9]+]] = OpConstantComposite %[[v4uchar]] %[[uchar_42]] %[[uchar_42]] %[[uchar_42]]
// CHECK:     OpExtInst %[[v4uchar]] %[[glsl_ext]] UClamp {{.*}} %[[lovec]] %[[hivec]]

kernel void test_clamp(global uchar3* out, global uchar3* in)
{
    *out = clamp(*in, (uchar3)7, (uchar3)42);
}


