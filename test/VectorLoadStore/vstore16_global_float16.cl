// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that vstore for float16 is supported.

// CHECK-DAG: [[UINT:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[RUNTIME_UINT:%[^ ]+]] = OpTypeRuntimeArray [[UINT]]
// CHECK-DAG: [[STRUCT_RUNTIME_UINT:%[^ ]+]] = OpTypeStruct [[RUNTIME_UINT]]
// CHECK-DAG: [[PTR_UINT:%[^ ]+]] = OpTypePointer StorageBuffer [[STRUCT_RUNTIME_UINT]]
//
// CHECK-DAG: [[FLOAT:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[RUNTIME_FLOAT:%[^ ]+]] = OpTypeRuntimeArray [[FLOAT]]
// CHECK-DAG: [[STRUCT_RUNTIME_FLOAT:%[^ ]+]] = OpTypeStruct [[RUNTIME_FLOAT]]
// CHECK-DAG: [[PTR_FLOAT:%[^ ]+]] = OpTypePointer StorageBuffer [[STRUCT_RUNTIME_FLOAT]]
//
// CHECK-DAG: [[FLOAT8:%[^ ]+]] = OpTypeVector [[FLOAT]] 4
// CHECK-DAG: [[RUNTIME_FLOAT8:%[^ ]+]] = OpTypeRuntimeArray [[FLOAT8]]
// CHECK-DAG: [[STRUCT_RUNTIME_FLOAT8:%[^ ]+]] = OpTypeStruct [[RUNTIME_FLOAT8]]
// CHECK-DAG: [[PTR_FLOAT8:%[^ ]+]] = OpTypePointer StorageBuffer [[STRUCT_RUNTIME_FLOAT8]]
//
// CHECK-DAG: [[INT_PTR:%[^ ]+]] = OpTypePointer StorageBuffer [[UINT]]
// CHECK-DAG: [[FLOAT_PTR_FLOAT8:%[^ ]+]] = OpTypePointer StorageBuffer [[FLOAT8]]
// CHECK-DAG: [[BUFFER_FLOAT_PTR:%[^ ]+]] = OpTypePointer StorageBuffer [[FLOAT]]
//
// CHECK-DAG: [[CST_0:%[^ ]+]]  = OpConstant [[UINT]] 0
// CHECK-DAG: [[CST_1:%[^ ]+]]  = OpConstant [[UINT]] 1
// CHECK-DAG: [[CST_2:%[^ ]+]]  = OpConstant [[UINT]] 2
// CHECK-DAG: [[CST_3:%[^ ]+]]  = OpConstant [[UINT]] 3
// CHECK-DAG: [[CST_4:%[^ ]+]]  = OpConstant [[UINT]] 4
// CHECK-DAG: [[CST_5:%[^ ]+]]  = OpConstant [[UINT]] 5
// CHECK-DAG: [[CST_6:%[^ ]+]]  = OpConstant [[UINT]] 6
// CHECK-DAG: [[CST_7:%[^ ]+]]  = OpConstant [[UINT]] 7
// CHECK-DAG: [[CST_8:%[^ ]+]]  = OpConstant [[UINT]] 8
// CHECK-DAG: [[CST_9:%[^ ]+]]  = OpConstant [[UINT]] 9
// CHECK-DAG: [[CST_10:%[^ ]+]] = OpConstant [[UINT]] 10
// CHECK-DAG: [[CST_11:%[^ ]+]] = OpConstant [[UINT]] 11
// CHECK-DAG: [[CST_12:%[^ ]+]] = OpConstant [[UINT]] 12
// CHECK-DAG: [[CST_13:%[^ ]+]] = OpConstant [[UINT]] 13
// CHECK-DAG: [[CST_14:%[^ ]+]] = OpConstant [[UINT]] 14
// CHECK-DAG: [[CST_15:%[^ ]+]] = OpConstant [[UINT]] 15
//
// CHECK-DAG: [[OFFSET:%[^ ]+]] = OpVariable [[PTR_UINT]]   StorageBuffer
// CHECK-DAG: [[DST:%[^ ]+]]    = OpVariable [[PTR_FLOAT]]  StorageBuffer
// CHECK-DAG: [[VALUES:%[^ ]+]] = OpVariable [[PTR_FLOAT8]] StorageBuffer
//
// CHECK-DAG: [[PTR:%[^ ]+]]   = OpAccessChain [[INT_PTR]] [[OFFSET]] [[CST_0]]
// CHECK-DAG: [[VAL_0:%[^ ]+]] = OpLoad [[UINT]] [[PTR]]
//
// CHECK-DAG: [[PTR_0:%[^ ]+]] = OpAccessChain [[FLOAT_PTR_FLOAT8]] [[VALUES]] [[CST_0]] [[CST_0]]
// CHECK-DAG: [[VAL_1:%[^ ]+]] = OpLoad [[FLOAT8]] [[PTR_0]]
//
// CHECK-DAG: [[A:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_1]] 0
// CHECK-DAG: [[B:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_1]] 1
// CHECK-DAG: [[C:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_1]] 2
// CHECK-DAG: [[D:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_1]] 3
//
// CHECK-DAG: [[PTR_1:%[^ ]+]] = OpAccessChain [[FLOAT_PTR_FLOAT8]] [[VALUES]] [[CST_0]] [[CST_1]]
// CHECK-DAG: [[VAL_2:%[^ ]+]] = OpLoad [[FLOAT8]] [[PTR_1]]
//
// CHECK-DAG: [[E:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_2]] 0
// CHECK-DAG: [[F:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_2]] 1
// CHECK-DAG: [[G:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_2]] 2
// CHECK-DAG: [[H:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_2]] 3
//
// CHECK-DAG: [[PTR_2:%[^ ]+]] = OpAccessChain [[FLOAT_PTR_FLOAT8]] [[VALUES]] [[CST_0]] [[CST_2]]
// CHECK-DAG: [[VAL_3:%[^ ]+]] = OpLoad [[FLOAT8]] [[PTR_2]]
//
// CHECK-DAG: [[I:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_3]] 0
// CHECK-DAG: [[J:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_3]] 1
// CHECK-DAG: [[K:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_3]] 2
// CHECK-DAG: [[L:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_3]] 3
//
// CHECK-DAG: [[PTR_3:%[^ ]+]] = OpAccessChain [[FLOAT_PTR_FLOAT8]] [[VALUES]] [[CST_0]] [[CST_3]]
// CHECK-DAG: [[VAL_4:%[^ ]+]] = OpLoad [[FLOAT8]] [[PTR_3]]
//
// CHECK-DAG: [[M:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_4]] 0
// CHECK-DAG: [[N:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_4]] 1
// CHECK-DAG: [[O:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_4]] 2
// CHECK-DAG: [[P:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_4]] 3
//
// CHECK-DAG: [[BASE_OFFSET:%[^ ]+]] = OpShiftLeftLogical [[UINT]] [[VAL_0]] [[CST_4]]
//
// CHECK-DAG: [[PTR_A:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[BASE_OFFSET]]
// CHECK-DAG: OpStore [[PTR_A]] [[A]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_1]]
// CHECK-DAG: [[PTR_B:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG: OpStore [[PTR_B]] [[B]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_2]]
// CHECK-DAG: [[PTR_C:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:  OpStore [[PTR_C]] [[C]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_3]]
// CHECK-DAG: [[PTR_D:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:   OpStore [[PTR_D]] [[D]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_4]]
// CHECK-DAG: [[PTR_E:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:  OpStore [[PTR_E]] [[E]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]]  [[CST_5]]
// CHECK-DAG: [[PTR_F:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:  OpStore [[PTR_F]] [[F]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]]  [[BASE_OFFSET]]  [[CST_6]]
// CHECK-DAG: [[PTR_G:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:  OpStore [[PTR_G]] [[G]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]]  [[BASE_OFFSET]]  [[CST_7]]
// CHECK-DAG: [[PTR_H:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:  OpStore [[PTR_H]] [[H]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_8]]
// CHECK-DAG: [[PTR_I:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:  OpStore [[PTR_I]] [[I]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_9]]
// CHECK-DAG: [[PTR_J:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:   OpStore [[PTR_J]] [[J]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_10]]
// CHECK-DAG: [[PTR_K:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:  OpStore [[PTR_K]] [[K]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]]  = OpBitwiseOr [[UINT]] [[BASE_OFFSET]]  [[CST_11]]
// CHECK-DAG: [[PTR_L:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:  OpStore [[PTR_L]] [[L]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]]  [[BASE_OFFSET]]  [[CST_12]]
// CHECK-DAG: [[PTR_M:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:  OpStore [[PTR_M]] [[M]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]]  [[BASE_OFFSET]]  [[CST_13]]
// CHECK-DAG: [[PTR_N:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:  OpStore [[PTR_N]] [[N]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_14]]
// CHECK-DAG: [[PTR_O:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:  OpStore [[PTR_O]] [[O]]
//
// CHECK-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_15]]
// CHECK-DAG: [[PTR_P:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG:   OpStore [[PTR_P]] [[P]]

kernel void test(global uint *offset, global float *dst,
                 global float4 *values) {
  // The following is optimised into 16 load/store pairs of instructions.
  float16 value = (float16)(values[0], values[1], values[2], values[3]);
  vstore16(value, *offset, dst);
}
