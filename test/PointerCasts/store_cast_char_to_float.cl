// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void writeToSoaBuffer(__global uchar* soa)
{
  const uint index = get_global_id(0);
  const size_t offset = (sizeof(float) / sizeof(uchar)) * index;
  __global float* data = (__global float*)(soa + offset);
  *data = (float)index;
}

// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[int0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK: [[int8:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 8
// CHECK: [[int16:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 16
// CHECK: [[int24:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 24
// CHECK: [[int1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK: [[shr:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[int]] {{.*}} [[int0]]
// CHECK: [[conv0:%[a-zA-Z0-9_]+]] = OpUConvert [[char]] [[shr]]
// CHECK: [[shr:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[int]] {{.*}} [[int8]]
// CHECK: [[conv8:%[a-zA-Z0-9_]+]] = OpUConvert [[char]] [[shr]]
// CHECK: [[shr:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[int]] {{.*}} [[int16]]
// CHECK: [[conv16:%[a-zA-Z0-9_]+]] = OpUConvert [[char]] [[shr]]
// CHECK: [[shr:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[int]] {{.*}} [[int24]]
// CHECK: [[conv24:%[a-zA-Z0-9_]+]] = OpUConvert [[char]] [[shr]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[int0]] [[idx:%[a-zA-Z0-9_]+]]
// CHECK: OpStore [[gep]] [[conv0]]
// CHECK: [[next:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[idx]] [[int1]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[int0]] [[next]]
// CHECK: OpStore [[gep]] [[conv8]]
// CHECK: [[idx:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[next]] [[int1]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[int0]] [[idx]]
// CHECK: OpStore [[gep]] [[conv16]]
// CHECK: [[next:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[idx]] [[int1]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[int0]] [[next]]
// CHECK: OpStore [[gep]] [[conv24]]
