// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[uint_9:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 9
// CHECK-DAG: %[[_arr_float_uint_9:[0-9a-zA-Z_]+]] = OpTypeArray %[[float]] %[[uint_9]]
// CHECK-DAG: %[[_struct_5:[0-9a-zA-Z_]+]] = OpTypeStruct %[[_arr_float_uint_9]]
// CHECK-DAG: %[[_ptr_Function__struct_5:[0-9a-zA-Z_]+]] = OpTypePointer Function %[[_struct_5]]
// CHECK-DAG: %[[__original_id_19:[0-9]+]] = OpConstantNull %[[_struct_5]]
// CHECK-DAG: %[[__original_id_39:[0-9]+]] = OpVariable %[[_ptr_Function__struct_5]] Function
// CHECK-DAG: %[[__original_id_40:[0-9]+]] = OpVariable %[[_ptr_Function__struct_5]] Function
// CHECK-DAG: %[[__original_id_41:[0-9]+]] = OpVariable %[[_ptr_Function__struct_5]] Function
// CHECK:     OpStore %[[__original_id_39]] %[[__original_id_19]]
// CHECK:     OpStore %[[__original_id_40]] %[[__original_id_19]]
// CHECK:     OpStore %[[__original_id_41]] %[[__original_id_19]]

typedef struct __Matrix3x3
{
  float m_data[9];
} Matrix3x3;

void addMat3x3(const __private Matrix3x3* lhs,
    const __private Matrix3x3* rhs,
    __private Matrix3x3* result)
{
  for (size_t i = 0; i < 9; ++i)
    result->m_data[i] = lhs->m_data[i] + rhs->m_data[i];
}

__kernel void test(__global Matrix3x3* inputs,
    __global Matrix3x3* outputs)
{
  const uint index = get_global_id(0);
  if (index == 0) {
      const Matrix3x3 lhs = inputs[2];
      const Matrix3x3 rhs = inputs[3];
      Matrix3x3 result = {{0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f}};
      addMat3x3(&lhs, &rhs, &result);
      outputs[1] = result;
  }
}

