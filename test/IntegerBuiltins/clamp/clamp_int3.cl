// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[glsl_ext:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:     %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[uint_7:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 7
// CHECK-DAG: %[[lovec:[0-9]+]] = OpConstantComposite %[[v3uint]] %[[uint_7]] %[[uint_7]] %[[uint_7]]
// CHECK-DAG: %[[uint_42:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 42
// CHECK-DAG: %[[hivec:[0-9]+]] = OpConstantComposite %[[v3uint]] %[[uint_42]] %[[uint_42]] %[[uint_42]]
// CHECK:     OpExtInst %[[v3uint]] %[[glsl_ext]] SClamp {{.*}} %[[lovec]] %[[hivec]]

kernel void test_clamp(global int3* out, global int3* in)
{
    *out = clamp(*in, (int3)7, (int3)42);
}

