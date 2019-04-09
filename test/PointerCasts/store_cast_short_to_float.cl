// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void writeToSoaBuffer(__global ushort* soa)
{
  const uint index = get_global_id(0);
  const size_t offset = (sizeof(float) / sizeof(ushort)) * index;
  __global float* data = (__global float*)(soa + offset);
  *data = (float)index;
}

// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[short:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
// CHECK: [[int0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK: [[int1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK: [[int65535:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 65535
// CHECK: [[int16:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 16
// CHECK: [[shr:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[int]] {{.*}} [[int0]]
// CHECK: [[and:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[shr]] [[int65535]]
// CHECK: [[conv0:%[a-zA-Z0-9_]+]] = OpUConvert [[short]] [[and]]
// CHECK: [[shr:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[int]] {{.*}} [[int16]]
// CHECK: [[and:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[shr]] [[int65535]]
// CHECK: [[conv16:%[a-zA-Z0-9_]+]] = OpUConvert [[short]] [[and]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[int0]] [[idx:%[a-zA-Z0-9_]+]]
// CHECK: OpStore [[gep]] [[conv0]]
// CHECK: [[next:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[idx]] [[int1]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[int0]] [[next]]
// CHECK: OpStore [[gep]] [[conv16]]

