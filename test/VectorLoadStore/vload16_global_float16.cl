// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that vload for float16 is supported.

// CHECK-DAG: [[UINT:%[0-9a-zA-Z_]+]]   = OpTypeInt 32 0
// CHECK-DAG: [[FLOAT:%[0-9a-zA-Z_]+]]  = OpTypeFloat 32
// CHECK-DAG: [[FLOAT_PTR:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[FLOAT]]
//
// CHECK-DAG: [[CST_0:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 0
// CHECK-DAG: [[CST_1:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 1
// CHECK-DAG: [[CST_2:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 2
// CHECK-DAG: [[CST_3:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 3
// CHECK-DAG: [[CST_4:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 4
// CHECK-DAG: [[CST_5:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 5
// CHECK-DAG: [[CST_6:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 6
// CHECK-DAG: [[CST_7:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 7
// CHECK-DAG: [[CST_8:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 8
// CHECK-DAG: [[CST_9:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 9
// CHECK-DAG: [[CST_10:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 10
// CHECK-DAG: [[CST_11:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 11
// CHECK-DAG: [[CST_12:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 12
// CHECK-DAG: [[CST_13:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 13
// CHECK-DAG: [[CST_14:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 14
// CHECK-DAG: [[CST_15:%[0-9a-zA-Z_]+]] = OpConstant [[UINT]] 15
//
//
// CHECK-NOT: DAG BARRIER

// We expect 16 loads from the StorageBuffer for "src".
//
// CHECK: [[BASE_OFFSET:%[0-9]+]] = OpShiftLeftLogical [[UINT]] {{%[0-9]+}} [[CST_4]]
//
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC:%[0-9a-zA-Z_]+]]
// CHECK-SAME: [[CST_0]] [[BASE_OFFSET]]

// CHECK: [[LOAD_0:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_1]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_1:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_2]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_2:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_3]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_3:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_4]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_4:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_5]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_5:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_6]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_6:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_7]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_7:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_8]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_8:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_9]]
// CHECK: [[PTR:%[0-9]+]]    = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_9:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]]  = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_10]]
// CHECK: [[PTR:%[0-9]+]]     = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_10:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]]  = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_11]]
// CHECK: [[PTR:%[0-9]+]]     = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_11:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]]  = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_12]]
// CHECK: [[PTR:%[0-9]+]]     = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_12:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]]  = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_13]]
// CHECK: [[PTR:%[0-9]+]]     = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_13:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]]  = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_14]]
// CHECK: [[PTR:%[0-9]+]]     = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_14:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]
//
// CHECK: [[OFFSET:%[0-9]+]]  = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_15]]
// CHECK: [[PTR:%[0-9]+]]     = OpAccessChain [[FLOAT_PTR]] [[SRC]] [[CST_0]] [[OFFSET]]
// CHECK: [[LOAD_15:%[0-9]+]] = OpLoad [[FLOAT]] [[PTR]]

kernel void test(uint offset, global float *src, global float *dst) {
  float16 in = vload16(offset, src);

  // Sink value to disable optimisations.
  dst[0] = in.s0 + in.s1 + in.s2 + in.s3 + in.s4 + in.s5 + in.s6 + in.s7 +
           in.s8 + in.s9 + in.sA + in.sB + in.sC + in.sD + in.sE + in.sF;
}
