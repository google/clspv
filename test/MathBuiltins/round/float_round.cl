// RUN: clspv %target %s -o %t.spv --use-native-builtins=fabs
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[ext_inst:%[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[sign_mask:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483648
// CHECK-DAG: [[rest_mask:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483647
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[float:%[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: [[halfway:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 0.5
// CHECK: [[ld:%[a-zA-Z0-9_]*]] = OpLoad [[float]]
// CHECK: [[fabs:%[a-zA-Z0-9_]+]] = OpExtInst [[float]] [[ext_inst]] FAbs [[ld]]
// CHECK: [[ceil:%[a-zA-Z0-9_]+]] = OpExtInst [[float]] [[ext_inst]] Ceil [[fabs]]
// CHECK: [[floor:%[a-zA-Z0-9_]+]] = OpExtInst [[float]] [[ext_inst]] Floor [[fabs]]
// CHECK: [[fract:%[a-zA-Z0-9_]+]] = OpExtInst [[float]] [[ext_inst]] Fract [[fabs]]
// CHECK: [[gte:%[a-zA-Z0-9_]+]] = OpFOrdGreaterThanEqual [[bool]] [[fract]] [[halfway]]
// CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect [[float]] [[gte]] [[ceil]] [[floor]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int]] [[ld]]
// CHECK: [[sign:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[cast]] [[sign_mask]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int]] [[sel]]
// CHECK: [[rest:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[cast]] [[rest_mask]]
// CHECK: [[combine:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[int]] [[rest]] [[sign]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[float]] [[combine]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float* b)
{
  *a = round(*b);
}
