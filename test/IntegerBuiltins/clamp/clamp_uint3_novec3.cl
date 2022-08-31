// RUN: clspv  %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -vec3-to-vec4 --enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[glsl_ext:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:     %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[uint_7:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 7
// CHECK-DAG: %[[lovec:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_7]] %[[uint_7]] %[[uint_7]]
// CHECK-DAG: %[[uint_42:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 42
// CHECK-DAG: %[[hivec:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_42]] %[[uint_42]] %[[uint_42]]
// CHECK:     OpExtInst %[[v4uint]] %[[glsl_ext]] UClamp {{.*}} %[[lovec]] %[[hivec]]

kernel void test_clamp(global uint3* out, global uint3* in)
{
    *out = clamp(*in, (uint3)7, (uint3)42);
}

