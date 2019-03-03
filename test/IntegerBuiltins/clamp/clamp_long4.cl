// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[glsl_ext:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK:     %[[v4ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 4
// CHECK-DAG: %[[ulong_7:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 7
// CHECK-DAG: %[[lovec:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_7]] %[[ulong_7]] %[[ulong_7]] %[[ulong_7]]
// CHECK-DAG: %[[ulong_42:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 42
// CHECK-DAG: %[[hivec:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_42]] %[[ulong_42]] %[[ulong_42]] %[[ulong_42]]
// CHECK:     OpExtInst %[[v4ulong]] %[[glsl_ext]] SClamp {{.*}} %[[lovec]] %[[hivec]]

kernel void test_clamp(global long4* out, global long4* in)
{
    *out = clamp(*in, (long4)7, (long4)42);
}

