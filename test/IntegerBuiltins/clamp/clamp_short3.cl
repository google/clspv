// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     %[[glsl_ext:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK:     %[[v3ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 3
// CHECK-DAG: %[[ushort_7:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 7
// CHECK-DAG: %[[lovec:[0-9]+]] = OpConstantComposite %[[v3ushort]] %[[ushort_7]] %[[ushort_7]] %[[ushort_7]]
// CHECK-DAG: %[[ushort_42:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 42
// CHECK-DAG: %[[hivec:[0-9]+]] = OpConstantComposite %[[v3ushort]] %[[ushort_42]] %[[ushort_42]] %[[ushort_42]]
// CHECK:     OpExtInst %[[v3ushort]] %[[glsl_ext]] SClamp {{.*}} %[[lovec]] %[[hivec]]

kernel void test_clamp(global short3* out, global short3* in)
{
    *out = clamp(*in, (short3)7, (short3)42);
}

