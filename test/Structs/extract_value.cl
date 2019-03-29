// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: %[[THING_TYPE_ID:[a-zA-Z0-9_]+]] = OpTypeStruct %[[FLOAT_TYPE_ID]] %[[FLOAT_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_42_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 42
// CHECK-DAG: %[[CONSTANT_2_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 2

struct Thing {
  float x;
  float y;
};

// CHECK: %[[A_ID:[a-zA-Z0-9_]*]] = OpFunction %[[THING_TYPE_ID]] Const
// CHECK: [[param:%[a-zA-Z0-9_]+]] = OpFunctionParameter %[[FLOAT_TYPE_ID]]
// CHECK: %[[A_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: [[add1:%[a-zA-Z0-9_]+]] = OpFAdd %[[FLOAT_TYPE_ID]] [[param]] %[[CONSTANT_42_ID]]
// CHECK: [[add2:%[a-zA-Z0-9_]+]] = OpFAdd %[[FLOAT_TYPE_ID]] [[param]] %[[CONSTANT_2_ID]]
// CHECK: [[construct:%[a-zA-Z0-9_]+]] = OpCompositeConstruct %[[THING_TYPE_ID]] [[add1]] [[add2]]
// CHECK: OpReturnValue [[construct]]

struct Thing a(float y) {
  struct Thing x;
  x.x = y + 42.0f;
  x.y = y + 2.0f;
  return x;
}

// CHECK: %[[B_ID:[a-zA-Z0-9_]*]] = OpFunction %[[FLOAT_TYPE_ID]] Const
// CHECK: [[param:%[a-zA-Z0-9_]+]] = OpFunctionParameter %[[FLOAT_TYPE_ID]]
// CHECK: %[[B_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[CALL_A_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[THING_TYPE_ID]] %[[A_ID]] [[param]]
// CHECK: %[[X_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[CALL_A_ID]] 0
// CHECK: %[[Y_ID:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[CALL_A_ID]] 1
// CHECK: %[[MUL_ID:[a-zA-Z0-9_]*]] = OpFMul %[[FLOAT_TYPE_ID]] %[[X_ID]] %[[Y_ID]]
// CHECK: OpReturnValue %[[MUL_ID]]

float b(float y) {
  return a(y).x * a(y).y;
}

// CHECK: OpFunction
// CHECK: %[[FOO_LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
// CHECK: %[[CALL_B_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[FLOAT_TYPE_ID]] %[[B_ID]]
// CHECK: OpStore {{.*}} %[[CALL_B_ID]]

void kernel __attribute__((reqd_work_group_size(42, 13, 2))) foo(global float* x, float y) {
  *x = b(y);
}
