// RUN: clspv %target --long-vector %s -o %t.spv -arch=spir
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target --long-vector %s -o %t.spv -arch=spir64
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that vload for float16 is supported.

// CHECK-DAG: [[UINT:%[0-9a-zA-Z_]+]]   = OpTypeInt 32 0
// CHECK-64-DAG: [[ULONG:%[0-9a-zA-Z_]+]]   = OpTypeInt 64 0
// CHECK-DAG: [[FLOAT:%[0-9a-zA-Z_]+]]  = OpTypeFloat 32
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
// CHECK-32-DAG: [[CST_8:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 8
// CHECK-32-DAG: [[CST_9:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 9
// CHECK-32-DAG: [[CST_10:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 10
// CHECK-32-DAG: [[CST_11:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 11
// CHECK-32-DAG: [[CST_12:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 12
// CHECK-32-DAG: [[CST_13:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 13
// CHECK-32-DAG: [[CST_14:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 14
// CHECK-32-DAG: [[CST_15:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 15
// CHECK-64-DAG: [[CST_3:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 3
// CHECK-64-DAG: [[CST_4:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 4
// CHECK-64-DAG: [[CST_5:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 5
// CHECK-64-DAG: [[CST_6:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 6
// CHECK-64-DAG: [[CST_7:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 7
// CHECK-64-DAG: [[CST_8:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 8
// CHECK-64-DAG: [[CST_9:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 9
// CHECK-64-DAG: [[CST_10:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 10
// CHECK-64-DAG: [[CST_11:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 11
// CHECK-64-DAG: [[CST_12:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 12
// CHECK-64-DAG: [[CST_13:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 13
// CHECK-64-DAG: [[CST_14:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 14
// CHECK-64-DAG: [[CST_15:%[0-9a-zA-Z_]+]] = OpConstant [[ULONG]] 15
//
//
// CHECK-NOT: DAG BARRIER

// We expect 16 loads from the StorageBuffer for "src".
//
// CHECK-64: [[BASE_OFFSET:%[0-9]+]] = OpShiftLeftLogical [[ULONG]] {{%[0-9]+}} [[CST_4]]
// CHECK-32: [[BASE_OFFSET:%[0-9]+]] = OpShiftLeftLogical [[UINT]] {{%[0-9]+}} [[CST_4]]
//
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC:%[0-9a-zA-Z_]+]]
// CHECK-SAME: [[CST_0]] [[BASE_OFFSET]]
//
// CHECK: [[LOAD_0:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_1_LONG]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_1]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_1:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_2_LONG]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_2]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_2:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_3]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_3]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_3:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_4]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_4]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_4:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_5]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_5]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_5:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_6]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_6]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_6:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_7]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_7]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_7:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_8]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_8]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_8:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_9]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_9]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_9:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_10]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_10]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_10:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_11]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_11]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_11:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_12]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_12]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_12:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_13]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_13]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_13:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_14]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_14]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_14:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK-64: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_15]]
// CHECK-32: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_15]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_15:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]

kernel void test(uint offset, global float *src, global float *dst) {
  float16 in = vload16(offset, src);

  // Sink value to disable optimisations.
  dst[0] = in.s0 + in.s1 + in.s2 + in.s3 + in.s4 + in.s5 + in.s6 + in.s7 +
           in.s8 + in.s9 + in.sA + in.sB + in.sC + in.sD + in.sE + in.sF;
}
