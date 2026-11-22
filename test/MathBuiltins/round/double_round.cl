// RUN: clspv %target %s -o %t.spv --use-native-builtins=fabs
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// round restores the sign of its input with copysign, using the
// 0x8000000000000000 sign bit mask and its 0x7fffffffffffffff complement.
// CHECK: [[ext_inst:%[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK-DAG: [[sign_mask:%[a-zA-Z0-9_]+]] = OpConstant [[long]] 9223372036854775808
// CHECK-DAG: [[rest_mask:%[a-zA-Z0-9_]+]] = OpConstant [[long]] 9223372036854775807
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[double:%[a-zA-Z0-9_]*]] = OpTypeFloat 64
// CHECK-DAG: [[halfway:%[a-zA-Z0-9_]+]] = OpConstant [[double]] 0.5
// CHECK: [[ld:%[a-zA-Z0-9_]*]] = OpLoad [[double]]
// CHECK: [[fabs:%[a-zA-Z0-9_]+]] = OpExtInst [[double]] [[ext_inst]] FAbs [[ld]]
// CHECK: [[ceil:%[a-zA-Z0-9_]+]] = OpExtInst [[double]] [[ext_inst]] Ceil [[fabs]]
// CHECK: [[floor:%[a-zA-Z0-9_]+]] = OpExtInst [[double]] [[ext_inst]] Floor [[fabs]]
// CHECK: [[fract:%[a-zA-Z0-9_]+]] = OpExtInst [[double]] [[ext_inst]] Fract [[fabs]]
// CHECK: [[gte:%[a-zA-Z0-9_]+]] = OpFOrdGreaterThanEqual [[bool]] [[fract]] [[halfway]]
// CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect [[double]] [[gte]] [[ceil]] [[floor]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[long]] [[ld]]
// CHECK: [[sign:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[long]] [[cast]] [[sign_mask]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[long]] [[sel]]
// CHECK: [[rest:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[long]] [[cast]] [[rest_mask]]
// CHECK: [[combine:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[long]] [[rest]] [[sign]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[double]] [[combine]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global double* a, global double* b)
{
  *a = round(*b);
}
