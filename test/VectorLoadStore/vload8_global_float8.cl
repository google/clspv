// RUN: clspv %target --long-vector %s -o %t.spv -arch=spir
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target --long-vector %s -o %t.spv -arch=spir64
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that vload for float8 is supported.

// CHECK-DAG: [[UINT:%[0-9a-zA-Z_]+]]   = OpTypeInt 32 0
// CHECK-64-DAG: [[ULONG:%[0-9a-zA-Z_]+]]   = OpTypeInt 64 0
// CHECK-DAG: [[FLOAT:%[0-9a-zA-Z_]+]]  = OpTypeFloat 32
//
// CHECK-DAG: [[FLOAT_PTR:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[FLOAT]]
//
// CHECK-DAG: [[CST_0:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 0
// CHECK-DAG: [[CST_1:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 1
// CHECK-DAG: [[CST_2:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 2
// CHECK-64-DAG: [[CST_1_LONG:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 1
// CHECK-64-DAG: [[CST_2_LONG:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 2
//
// CHECK-32-DAG: [[CST_3:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 3
// CHECK-32-DAG: [[CST_4:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 4
// CHECK-32-DAG: [[CST_5:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 5
// CHECK-32-DAG: [[CST_6:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 6
// CHECK-32-DAG: [[CST_7:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 7
// CHECK-64-DAG: [[CST_3:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 3
// CHECK-64-DAG: [[CST_4:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 4
// CHECK-64-DAG: [[CST_5:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 5
// CHECK-64-DAG: [[CST_6:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 6
// CHECK-64-DAG: [[CST_7:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 7
//
// CHECK-NOT: DAG BARRIER
//
// CHECK-64: [[BASE_OFFSET_:%[0-9]+]] = OpShiftLeftLogical [[ULONG]] {{%[0-9]+}} [[CST_5]]
// CHECK-64: [[BASE_OFFSET:%[0-9]+]] = OpShiftRightLogical [[ULONG]] {{%[0-9]+}} [[CST_2_LONG]]
// CHECK-32: [[BASE_OFFSET_:%[0-9]+]] = OpShiftLeftLogical [[UINT]] {{%[0-9]+}} [[CST_5]]
// CHECK-32: [[BASE_OFFSET:%[0-9]+]] = OpShiftRightLogical [[UINT]] {{%[0-9]+}} [[CST_2]]
//
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC:%[0-9a-zA-Z_]+]]
// CHECK-SAME: [[CST_0]] [[BASE_OFFSET]]
// CHECK: [[LOAD_0:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpIAdd [[ULONG]] [[BASE_OFFSET]] [[CST_1_LONG]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpIAdd [[UINT]] [[BASE_OFFSET]] [[CST_1]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_1:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpIAdd [[ULONG]] [[BASE_OFFSET]] [[CST_2_LONG]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpIAdd [[UINT]] [[BASE_OFFSET]] [[CST_2]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_2:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpIAdd [[ULONG]] [[BASE_OFFSET]] [[CST_3]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpIAdd [[UINT]] [[BASE_OFFSET]] [[CST_3]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_3:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpIAdd [[ULONG]] [[BASE_OFFSET]] [[CST_4]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpIAdd [[UINT]] [[BASE_OFFSET]] [[CST_4]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_4:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpIAdd [[ULONG]] [[BASE_OFFSET]] [[CST_5]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpIAdd [[UINT]] [[BASE_OFFSET]] [[CST_5]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_5:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpIAdd [[ULONG]] [[BASE_OFFSET]] [[CST_6]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpIAdd [[UINT]] [[BASE_OFFSET]] [[CST_6]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_6:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpIAdd [[ULONG]] [[BASE_OFFSET]] [[CST_7]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpIAdd [[UINT]] [[BASE_OFFSET]] [[CST_7]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_7:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]

kernel void test(uint offset, global float *src, global float *dst) {
  float8 in = vload8(offset, src);

  // Sink value to disable optimisations.
  dst[0] = in.s0 + in.s1 + in.s2 + in.s3 + in.s4 + in.s5 + in.s6 + in.s7;
}
